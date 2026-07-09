# Especificação: Sistema de Comentários com Hotwire — Rails 8

## 1. Arquitetura Geral

**Stack:** Rails 8 + PostgreSQL + Devise + Hotwire (Turbo Streams + Stimulus) + Solid Trifecta (SolidCache / SolidQueue)

**Princípios herdados do Lobsters:**
- Aninhamento via `parent_comment_id` + `depth` (sem gem)
- Árvore plana ordenada em 1 query (CTE recursiva)
- Colapso/expansão via CSS puro (`input:checked ~`)
- Score de confiança (Wilson) para ordenação entre irmãos
- `short_id` alfanumérico para URLs (esconde IDs sequenciais)
- Bulk-hydration de votos do usuário (padrão CommentVoteHydrator)

**Melhorias sobre o Lobsters:**
- PostgreSQL `SEARCH DEPTH FIRST BY` substitui o hack de `confidence_order_path` com tamanho fixo
- Turbo Streams substitui todo o JS manual de fetch/substituição de DOM
- Stimulus controllers modulares (vote, reply, collapse, flag, edit)
- Votos atômicos em SQL (elimina race condition)
- Design polimórfico (`commentable`)

---

## 2. Database Schema

### 2.1 Tabela `comments`

```ruby
create_table :comments do |t|
  t.references :commentable, polymorphic: true, null: false
  t.references :user, null: false, foreign_key: true
  t.references :parent, foreign_key: { to_table: :comments }

  t.string  :short_id, null: false   # ex: "a3x9k" — URLs amigáveis
  t.integer :depth, null: false, default: 0       # profundidade na árvore (0 = raiz)
  t.integer :reply_count, null: false, default: 0 # counter cache de filhos diretos
  t.integer :score, null: false, default: 1       # ups - downs (sem flags)

  t.text    :body                        # markdown cru
  t.text    :body_html                   # HTML renderizado (cache)

  t.decimal :confidence, precision: 20, scale: 19, null: false  # Wilson score
  t.boolean :deleted, null: false, default: false               # soft delete
  t.boolean :moderated, null: false, default: false             # remoção por mod

  t.datetime :last_edited_at
  t.timestamps
end

add_index :comments, :short_id, unique: true
add_index :comments, [:commentable_type, :commentable_id, :parent_id]  # CTE push-down
add_index :comments, [:commentable_type, :commentable_id, :created_at] # fallback ordering
add_index :comments, [:user_id, :created_at]
```

### 2.2 Tabela `votes` (polimórfica para comentários)

```ruby
create_table :votes do |t|
  t.references :user, null: false, foreign_key: true
  t.references :comment, null: false, foreign_key: true
  t.integer :value, null: false    # +1 (up) ou -1 (down)
  t.timestamps
end

add_index :votes, [:comment_id, :user_id], unique: true
add_index :votes, [:user_id, :comment_id]
```

### 2.3 Tabela `flags`

```ruby
create_table :flags do |t|
  t.references :user, null: false, foreign_key: true
  t.references :comment, null: false, foreign_key: true
  t.string :reason, null: false    # "spam", "harassment", "offtopic" etc
  t.text :note                     # motivo adicional opcional
  t.boolean :resolved, null: false, default: false
  t.references :resolved_by, foreign_key: { to_table: :users }
  t.timestamps
end

add_index :flags, [:comment_id, :user_id], unique: true
```

---

## 3. Models

### 3.1 `Comment`

```ruby
class Comment < ApplicationRecord
  MAX_DEPTH = 6
  COLLAPSE_SCORE = -5
  MAX_EDIT_MINUTES = 30
  SCORE_RANGE_TO_HIDE = (-3..3)

  # --- Associações ---
  belongs_to :commentable, polymorphic: true, touch: true
  belongs_to :user
  belongs_to :parent, class_name: "Comment", optional: true,
    counter_cache: :reply_count, touch: :last_reply_at
  has_many :replies, class_name: "Comment", foreign_key: :parent_id,
    dependent: :restrict_with_error
  has_many :votes, dependent: :delete_all
  has_many :flags, dependent: :destroy

  # --- Virtuals (preenchidos pelo hydrator) ---
  attribute :current_user_vote, :integer        # +1, 0, -1, ou nil
  attribute :current_user_flagged, :boolean
  attribute :current_user_replied, :boolean

  # --- Callbacks ---
  before_create :assign_short_id_and_depth
  after_create :record_author_upvote, :broadcast_appearance

  # --- Scopes ---
  scope :visible, -> { where(deleted: false, moderated: false) }
  scope :roots, -> { where(parent_id: nil) }
  scope :with_includes, -> { includes(:user, votes: :user) }

  # --- Métodos de árvore ---
  def self.thread_tree(commentable)
    # CTE recursiva com SEARCH DEPTH FIRST BY (PostgreSQL nativo)
    Comment.find_by_sql([<<~SQL, commentable_type: commentable.class.name, commentable_id: commentable.id])
      WITH RECURSIVE thread AS (
        SELECT c.*, 0 AS sort_depth
        FROM comments c
        WHERE c.commentable_type = :commentable_type
          AND c.commentable_id = :commentable_id
          AND c.parent_id IS NULL
        UNION ALL
        SELECT c.*, thread.sort_depth + 1
        FROM comments c
        JOIN thread ON c.parent_id = thread.id
      )
      SEARCH DEPTH FIRST BY created_at SET sort_order
      SELECT * FROM thread
      ORDER BY sort_order
    SQL
  end

  # --- Métodos de negócio ---
  def depth_permits_reply?
    depth < MAX_DEPTH
  end

  def editable_by?(user)
    user == self.user && created_at > MAX_EDIT_MINUTES.minutes.ago && !deleted?
  end

  def destroyable_by?(user)
    user == self.user || user.admin?
  end

  def flaggable_by?(user)
    user != self.user && !deleted? && !moderated? &&
      !flags.exists?(user: user)
  end

  def collapsed_by_default?
    score <= COLLAPSE_SCORE || moderated? || user.banned?
  end

  def show_score?
    score > SCORE_RANGE_TO_HIDE.last || score < SCORE_RANGE_TO_HIDE.first ||
      created_at < 24.hours.ago
  end

  def update_score!
    # Atômico — recalcula do zero, sem race condition
    Comment.connection.execute(<<~SQL.squish)
      UPDATE comments SET
        score = COALESCE((SELECT SUM(value) FROM votes WHERE comment_id = #{id}), 1),
        confidence = #{wilson_confidence}
      WHERE id = #{id}
    SQL
    reload
  end

  private

  def assign_short_id_and_depth
    self.short_id = Nanoid.generate(size: 6)
    if parent
      self.depth = parent.depth + 1
    else
      self.depth = 0
    end
  end

  def record_author_upvote
    votes.create!(user: user, value: 1)
    update_score!
  end

  def broadcast_appearance
    # Turbo Stream broadcast (ver seção 5)
  end

  def wilson_confidence
    # Fórmula de Wilson — limite inferior do intervalo de confiança de 80%
    # (mesma do Lobsters/Reddit)
  end
end
```

### 3.2 `Vote`

```ruby
class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :comment, touch: true

  validates :value, inclusion: { in: [-1, 1] }
  validates :comment_id, uniqueness: { scope: :user_id }

  scope :for_user, ->(user) { where(user: user) }

  def self.cast(user:, comment:, value:)
    vote = find_or_initialize_by(user: user, comment: comment)

    return vote.destroy! if vote.value == value # toggle off
    return if vote.value == value                # no-op

    vote.update!(value: value)
    comment.update_score!
    vote
  end

  # Bulk-load para hydration
  def self.indexed_by_comment(user, comments)
    return {} unless user
    where(user: user, comment: comments)
      .pluck(:comment_id, :value)
      .to_h
  end
end
```

### 3.3 `Flag`

```ruby
class Flag < ApplicationRecord
  REASONS = %w[spam harassment offtopic inappropriate].freeze

  belongs_to :user
  belongs_to :comment
  belongs_to :resolved_by, class_name: "User", optional: true

  validates :reason, inclusion: { in: REASONS }
  validates :comment_id, uniqueness: { scope: :user_id }
end
```

### 3.4 `CommentVoteHydrator` (pattern do Lobsters)

```ruby
class CommentVoteHydrator
  include Enumerable

  delegate :size, :empty?, :any?, to: :@comments

  def initialize(comments, user)
    @comments = comments
    @user = user
    if user && comments.any?
      ids = comments.map(&:id)
      @votes  = Vote.indexed_by_comment(user, ids)
      @flags  = Flag.where(user: user, comment_id: ids).pluck(:comment_id).to_set
      @replied = Comment.where(user: user, parent_id: ids).pluck(:parent_id).to_set
    else
      @votes = {}; @flags = Set.new; @replied = Set.new
    end
  end

  def each
    @comments.each do |c|
      c.current_user_vote    = @votes[c.id]
      c.current_user_flagged = @flags.include?(c.id)
      c.current_user_replied = @replied.include?(c.id)
      yield c
    end
  end
end
```

### 3.5 `Commentable` concern (módulo)

```ruby
module Commentable
  extend ActiveSupport::Concern

  included do
    has_many :comments, as: :commentable, dependent: :destroy
  end

  def accepting_comments?
    !locked?  # implementar conforme o modelo
  end
end
```

---

## 4. Routes

```ruby
# config/routes.rb
resources :comments, only: [:create, :edit, :update, :destroy] do
  member do
    get  :reply       # formulário de resposta (Turbo Frame)
    post :upvote      # POST /comments/:id/upvote
    post :downvote    # POST /comments/:id/downvote
    post :flag        # POST /comments/:id/flag
    post :unflag      # POST /comments/:id/unflag
    post :undelete    # POST /comments/:id/undelete (autor restaura)
  end
end

# Short ID redirect
get "/c/:short_id", to: "comments#show", as: :comment_permalink
```

---

## 5. Controllers & Turbo Streams

### 5.1 `CommentsController`

```ruby
class CommentsController < ApplicationController
  before_action :authenticate_user!, except: [:show]
  before_action :find_commentable, only: [:create]
  before_action :find_comment, only: [:edit, :update, :destroy, :reply,
                                       :upvote, :downvote, :flag, :unflag, :undelete]

  # GET /c/:short_id — redireciona para o comentável com anchor
  def show
    comment = Comment.find_by!(short_id: params[:short_id])
    redirect_to polymorphic_path(comment.commentable, anchor: dom_id(comment))
  end

  # POST /comments — criar comentário (top-level ou resposta)
  def create
    @comment = @commentable.comments.new(comment_params)
    @comment.user = current_user
    @comment.parent = Comment.find_by(short_id: params[:parent_short_id])

    if @comment.save
      respond_to do |format|
        format.turbo_stream  # create.turbo_stream.erb
        format.html { redirect_to polymorphic_path(@commentable, anchor: dom_id(@comment)) }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /comments/:id/reply — retorna formulário inline (Turbo Frame)
  def reply
    @reply = @comment.commentable.comments.new(parent: @comment)
    render partial: "comments/form", locals: { comment: @reply }
  end

  # PATCH /comments/:id — editar
  def update
    if @comment.update(comment_params.merge(last_edited_at: Time.current))
      respond_to do |format|
        format.turbo_stream  # update.turbo_stream.erb
        format.html { redirect_to polymorphic_path(@comment.commentable, anchor: dom_id(@comment)) }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /comments/:id — soft delete
  def destroy
    @comment.soft_delete! if @comment.destroyable_by?(current_user)
    respond_to(&:turbo_stream)
  end

  # POST /comments/:id/upvote
  def upvote
    Vote.cast(user: current_user, comment: @comment, value: 1)
    hydrate_and_respond
  end

  # POST /comments/:id/downvote
  def downvote
    Vote.cast(user: current_user, comment: @comment, value: -1)
    hydrate_and_respond
  end

  # POST /comments/:id/flag
  def flag
    @comment.flags.create!(user: current_user, reason: params[:reason])
    hydrate_and_respond
  end

  # POST /comments/:id/unflag
  def unflag
    @comment.flags.find_by!(user: current_user).destroy!
    hydrate_and_respond
  end

  # POST /comments/:id/undelete
  def undelete
    @comment.update!(deleted: false) if @comment.user == current_user
    hydrate_and_respond
  end

  private

  def find_commentable
    # params[:comment] contém :commentable_type e :commentable_id
    @commentable = GlobalID::Locator.locate(params[:comment][:commentable_gid])
  end

  def find_comment
    @comment = Comment.find_by!(short_id: params[:id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end

  def hydrate_and_respond
    @comment = CommentVoteHydrator.new([@comment], current_user).first
    respond_to do |format|
      format.turbo_stream  # vota/flag/delete/undelete
      format.html { redirect_to polymorphic_path(@comment.commentable, anchor: dom_id(@comment)) }
    end
  end
end
```

### 5.2 Turbo Stream templates

**`app/views/comments/create.turbo_stream.erb`**

```erb
<%# Se é resposta (tem pai), insere dentro da sub-árvore do pai %>
<% if @comment.parent %>
  <%= turbo_stream.append dom_id(@comment.parent, :replies) do %>
    <%= render "comments/comment", comment: @comment %>
  <% end %>
<% else %>
  <%= turbo_stream.append "comments_tree" do %>
    <%= render "comments/comment", comment: @comment %>
  <% end %>
<% end %>

<%# Limpa o formulário %>
<%= turbo_stream.replace "comment_form" do %>
  <%= render "comments/form", comment: @commentable.comments.new %>
<% end %>
```

**`app/views/comments/update.turbo_stream.erb`**

```erb
<%= turbo_stream.replace dom_id(@comment) do %>
  <%= render "comments/comment", comment: @comment %>
<% end %>
```

**`app/views/comments/destroy.turbo_stream.erb`**

```erb
<%= turbo_stream.replace dom_id(@comment) do %>
  <%= render "comments/gone", comment: @comment %>
<% end %>
```

**`app/views/comments/upvote.turbo_stream.erb`** (mesmo padrão para downvote, flag, unflag, undelete)

```erb
<%= turbo_stream.replace dom_id(@comment) do %>
  <%= render "comments/comment", comment: @comment %>
<% end %>
```

---

## 6. Views & Hotwire

### 6.1 Árvore de comentários: `_tree.html.erb`

```erb
<%# locals: (commentable:, comments:) — comments é o array flat ordenado %>
<% comments = CommentVoteHydrator.new(comments, current_user) %>

<div id="comments_tree"
     data-controller="comments-tree"
     data-comments-tree-commentable-type="<%= commentable.class.name %>"
     data-comments-tree-commentable-id="<%= commentable.id %>">

  <% previous_depth = nil %>
  <% top_depth = nil %>

  <% comments.each do |comment| %>
    <% if previous_depth %>
      <% if comment.depth > previous_depth %>
        <ol class="comments" id="<%= dom_id(comment.parent, :replies) %>">
      <% else %>
        </ol></li>
        <% (previous_depth - comment.depth).times do %>
          </ol></li>
        <% end %>
      <% end %>
    <% end %>

    <% previous_depth = comment.depth %>
    <% top_depth ||= comment.depth %>

    <li class="comments_subtree" id="<%= dom_id(comment, :subtree) %>">
      <%= render "comments/comment", comment: comment %>
  <% end %>

  <% if top_depth %>
    </ol></li>
    <% (previous_depth - top_depth).times do %>
      </ol></li>
    <% end %>
  <% end %>

</div>
```

### 6.2 Cada comentário: `_comment.html.erb`

```erb
<%# locals: (comment:) %>

<% collapsed = comment.collapsed_by_default? %>

<article id="<%= dom_id(comment) %>"
         class="comment
           <%= "upvoted"  if comment.current_user_vote == 1 %>
           <%= "downvoted" if comment.current_user_vote == -1 %>
           <%= "flagged"  if comment.current_user_flagged %>
           <%= "replied"  if comment.current_user_replied %>
           <%= "gone"     if comment.deleted? || comment.moderated? %>"
         data-controller="comment"
         data-comment-score="<%= comment.score %>">

  <%# Checkbox invisível para collapse via CSS %>
  <label class="comment_folder">
    <input type="checkbox"
           class="comment_folder_button"
           data-comment-target="collapseCheckbox"
           data-action="change->comment#persistCollapse"
           <%= "checked" if collapsed %>>
  </label>

  <div class="comment_score" data-comment-target="score">
    <%= render "comments/score", comment: comment %>
  </div>

  <div class="comment_content">
    <div class="comment_meta">
      <%= link_to comment.user.username, user_path(comment.user) %>
      <time datetime="<%= comment.created_at.iso8601 %>"
            title="<%= l(comment.created_at, format: :long) %>">
        <%= time_ago_in_words(comment.created_at) %> ago
      </time>
      <% if comment.last_edited_at && comment.last_edited_at > comment.created_at %>
        (edited)
      <% end %>
    </div>

    <% if comment.deleted? %>
      <p class="comment_gone">[deleted by author]</p>
    <% elsif comment.moderated? %>
      <p class="comment_gone">[removed by moderator]</p>
    <% else %>
      <div class="comment_body">
        <%= comment.body_html.html_safe %>
      </div>
    <% end %>

    <div class="comment_actions" data-comment-target="actions">
      <%= render "comments/actions", comment: comment %>
    </div>
  </div>
</article>
```

### 6.3 Ações: `_actions.html.erb`

```erb
<%# locals: (comment:) %>

<%= link_to "reply", reply_comment_path(comment),
    class: "comment_replier",
    data: { turbo_frame: dom_id(comment, :reply_form) } %>

<% if comment.editable_by?(current_user) %>
  <%= link_to "edit", edit_comment_path(comment),
      data: { turbo_frame: dom_id(comment, :body) } %>
<% end %>

<% if comment.destroyable_by?(current_user) %>
  <%= button_to "delete", comment_path(comment), method: :delete,
      class: "link_button",
      form: { data: { turbo_confirm: "Delete this comment?" } } %>
<% end %>

<%= button_to "▲ upvote", upvote_comment_path(comment), method: :post,
    class: "vote_button #{'active' if comment.current_user_vote == 1}",
    data: { action: "comment#upvote" } %>

<%= button_to "▼ downvote", downvote_comment_path(comment), method: :post,
    class: "vote_button #{'active' if comment.current_user_vote == -1}",
    data: { action: "comment#downvote" } %>

<% if comment.flaggable_by?(current_user) %>
  <%= button_to "flag", flag_comment_path(comment), method: :post,
      class: "link_button",
      params: { reason: "" },
      form: { data: { turbo_confirm: "Flag this comment?" } } %>
<% end %>
```

### 6.4 Formulário de resposta: `_reply_frame.html.erb`

```erb
<%# Renderizado dentro de um Turbo Frame lazy %>
<%= turbo_frame_tag dom_id(comment, :reply_form) do %>
  <div class="reply_form">
    <%= form_with model: [comment.commentable, Comment.new],
          data: { controller: "comment-form", action: "turbo:submit-end->comment-form#reset" } do |f| %>
      <%= f.hidden_field :commentable_type, value: comment.commentable_type %>
      <%= f.hidden_field :commentable_id,   value: comment.commentable_id %>
      <%= f.hidden_field :parent_short_id,  value: comment.short_id %>
      <%= f.text_area :body, rows: 3, data: { comment_form_target: "textarea" } %>
      <%= f.submit "Reply" %>
      <%= button_tag "Cancel", type: "button",
            data: { action: "comment-form#cancel" } %>
      <%= button_tag "Preview", type: "button",
            data: { action: "comment-form#preview" } %>
    <% end %>
  </div>
<% end %>
```

---

## 7. Stimulus Controllers

### 7.1 `comment_controller.js` — Ações do comentário individual

```javascript
// app/javascript/controllers/comment_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["collapseCheckbox", "score", "actions"]

  persistCollapse(event) {
    const commentableType = this.element.closest("[data-comments-tree-commentable-type]")
      ?.dataset.commentsTreeCommentableType
    const commentableId = this.element.closest("[data-comments-tree-commentable-id]")
      ?.dataset.commentsTreeCommentableId
    if (!commentableType || !commentableId) return

    const key = `collapse_${commentableType}_${commentableId}`
    const state = JSON.parse(localStorage.getItem(key) || "{}")
    if (event.target.checked) {
      state[this.element.id] = true
    } else {
      delete state[this.element.id]
    }
    localStorage.setItem(key, JSON.stringify(state))
  }

  // Atualização otimista do score antes do Turbo Stream chegar
  upvote(event) {
    this._optimisticVote(1, event)
  }

  downvote(event) {
    this._optimisticVote(-1, event)
  }

  _optimisticVote(value, event) {
    event.preventDefault()
    const scoreEl = this.scoreTarget
    const delta = value === 1 ? 1 : -1
    const prev = parseInt(this.element.dataset.commentScore)
    scoreEl.textContent = prev + delta
    this.element.dataset.commentScore = prev + delta

    // Envia via Turbo (a resposta do servidor corrigirá se necessário)
    event.target.closest("form").requestSubmit()
  }
}
```

### 7.2 `comment_form_controller.js` — Formulário de comentário

```javascript
// app/javascript/controllers/comment_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea"]

  reset() {
    this.textareaTarget.value = ""
    this.textareaTarget.dispatchEvent(new Event("input")) // resize auto-growing
  }

  cancel(event) {
    event.preventDefault()
    // Se está editando, recarrega o comentário original
    const shortId = this.element.dataset.commentShortId
    if (shortId) {
      this.element.closest("turbo-frame").reload()
    } else {
      this.element.closest(".reply_form, .comment_form_container").remove()
    }
  }

  preview(event) {
    event.preventDefault()
    // POST com preview=true, renderiza o corpo em um div temporário
    // ou usa markdown-it no cliente para preview instantâneo
  }
}
```

### 7.3 `comments_tree_controller.js` — Árvore de comentários

```javascript
// app/javascript/controllers/comments_tree_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = []

  connect() {
    // Restaura estado de collapse do localStorage
    const type = this.element.dataset.commentsTreeCommentableType
    const id   = this.element.dataset.commentsTreeCommentableId
    const key  = `collapse_${type}_${id}`
    const state = JSON.parse(localStorage.getItem(key) || "{}")

    Object.keys(state).forEach(commentId => {
      const checkbox = this.element.querySelector(`#${commentId} .comment_folder_button`)
      if (checkbox) checkbox.checked = true
    })
  }
}
```

---

## 8. Sistema de Votos

### Fluxo de voto

```
Usuário clica upvote/downvote
  → comment_controller.js faz atualização otimista do score
  → form.requestSubmit() envia POST /comments/:id/upvote
  → Vote.cast (model) — atômico:
    1. find_or_initialize_by(user:, comment:)
    2. Se já votou igual → destrói voto (toggle off)
    3. Se diferente ou novo → upsert com novo value
    4. comment.update_score! recalcula score e confidence via SQL UPDATE
  → Turbo Stream substitui o elemento do comentário com score real
```

### `update_score!` (atômico, sem race condition)

```sql
UPDATE comments SET
  score = COALESCE((SELECT SUM(value) FROM votes WHERE comment_id = :id), 1),
  confidence = :wilson_value
WHERE id = :id
```

Diferente do Lobsters (que usa `score_delta` em Ruby + SQL), aqui o cálculo é 100% no banco. O `SELECT SUM` dentro do `UPDATE` é atômico na mesma transação.

### `wilson_confidence` — implementação Ruby chamada no SQL

```ruby
def self.wilson_confidence(ups, downs)
  return 0 if ups + downs == 0

  n = ups + downs
  z = 1.281551565545 # 80% confidence (z-score)
  phat = ups.to_f / n

  (phat + z*z/(2*n) - z * Math.sqrt((phat*(1-phat) + z*z/(4*n))/n)) / (1 + z*z/n)
end
```

- Comentários com mais upvotes e menos downvotes = confiança mais alta
- Entre irmãos (mesmo pai), ordena-se por `confidence DESC, created_at ASC`
- A CTE com `SEARCH DEPTH FIRST BY confidence DESC, created_at ASC SET sort_order` resolve a ordenação

---

## 9. Moderação

### Flag

- Usuário clica "flag" → modal com select de motivo (spam, harassment, offtopic, inappropriate)
- Flag é um registro separado do voto (`flags` table)
- Um usuário só pode flaggear 1x por comentário
- Comentário com ≥ N flags (ex: 3) é automaticamente colapsado por padrão
- **Não destrói** o comentário — apenas sinaliza para moderação

### Ações de moderador

```ruby
# Mod::CommentsController (namespace admin/mod)
class Mod::CommentsController < ApplicationController
  before_action :authenticate_user!, :require_moderator!

  def destroy  # mod-delete (diferente do soft-delete do autor)
    @comment.moderated_delete!(reason: params[:reason])
    redirect_to @comment.commentable
  end

  def resolve_flags
    @comment.flags.update_all(resolved: true, resolved_by: current_user)
  end
end
```

### `Comment#moderated_delete!`

```ruby
def moderated_delete!(reason:)
  update!(moderated: true, moderated_reason: reason)
  # Não remove o corpo para auditoria, mas o renderiza como "[removed by moderator]"
end
```

### Dashboard de flags (para moderadores)

- Página `/mod/flags` — tabela com comentários mais flaggeados, agrupados por `comment_id`, com contagem
- Ação de "dismiss flags" ou "remove comment" para cada item

---

## 10. Otimização da Árvore

### 10.1 CTE com `SEARCH DEPTH FIRST BY` (PostgreSQL)

Substitui o hack `confidence_order_path` do Lobsters:

```sql
WITH RECURSIVE thread AS (
    SELECT c.*, 0 AS depth_cte
    FROM comments c
    WHERE c.commentable_type = 'Article'
      AND c.commentable_id = 42
      AND c.parent_id IS NULL
    UNION ALL
    SELECT c.*, thread.depth_cte + 1
    FROM comments c
    JOIN thread ON c.parent_id = thread.id
)
SEARCH DEPTH FIRST BY confidence DESC, created_at ASC SET sort_order
SELECT * FROM thread
WHERE deleted = false AND moderated = false
ORDER BY sort_order
LIMIT 500
```

**Vantagens sobre o Lobsters:**
- Sem limite de profundidade na query (o `MAX_DEPTH` existe no model, mas não é necessário para a CTE)
- Sem coluna `confidence_order` binária de 3 bytes
- Sem coluna `thread_id` (se não precisar da feature de rate-limit por thread)
- Sem tamanho fixo de `COP_LENGTH`
- `sort_order` é gerado nativamente pelo PostgreSQL (tipo `RECORD` ou `BIGINT` interno)

### 10.2 Colunas pré-computadas (mantidas do Lobsters)

| Coluna | Propósito | Atualização |
|---|---|---|
| `depth` | Evita calcular profundidade na CTE; usado na view para indentação | `before_create` |
| `reply_count` | Counter cache — evita `COUNT(*)` para mostrar "N replies" | `belongs_to :parent, counter_cache: :reply_count` |
| `score` | Denormalizado — evita `SUM(votes.value)` em cada renderização | `update_score!` após cada voto |
| `confidence` | Denormalizado — usado na ordenação da CTE | `update_score!` |

### 10.3 Bulk-hydration (via `CommentVoteHydrator`)

Após a CTE retornar o array plano de comentários, antes de renderizar:

```ruby
@comments = Comment.thread_tree(@article)
@comments = CommentVoteHydrator.new(@comments, current_user)
```

O hydrator faz **3 queries** no total (não N+1):
1. `Vote.indexed_by_comment(user, ids)` → Hash `{comment_id => value}`
2. `Flag.where(user:, comment_id: ids).pluck(:comment_id)` → Set
3. `Comment.where(user:, parent_id: ids).pluck(:parent_id)` → Set

### 10.4 Caching com SolidCache

```ruby
# Cache do HTML renderizado da árvore (invalida quando novo comentário é criado)
Rails.cache.fetch(
  ["comments_tree", commentable, commentable.comments.maximum(:updated_at)],
  expires_in: 5.minutes
) do
  render "comments/tree", commentable: commentable
end
```

Para usuários logados, faz cache do HTML base (sem dados de voto) e aplica hydration no cliente — ou usa `turbo-cache` com refresh condicional.

### 10.5 Paginação para threads grandes

Se uma árvore tiver mais de 500 comentários, usar `LIMIT/OFFSET` na CTE ou lazy-load de sub-árvores via Turbo Frames:

```erb
<% if comment.reply_count > 10 && comment.depth <= 2 %>
  <%= turbo_frame_tag dom_id(comment, :children),
        src: subthread_comments_path(comment),
        loading: :lazy %>
<% end %>
```

---

## 11. Jobs & Notificações (SolidQueue)

### 11.1 `NotifyCommentJob`

```ruby
class NotifyCommentJob < ApplicationJob
  queue_as :default

  def perform(comment)
    # 1. Notificar autor do comentário pai (resposta)
    if comment.parent
      CommentMailer.reply_notification(comment).deliver_later
    end

    # 2. Notificar autor do post/artigo (novo comentário)
    if comment.commentable.respond_to?(:user) && comment.user != comment.commentable.user
      CommentMailer.new_comment_notification(comment).deliver_later
    end

    # 3. Notificar @mentions no corpo do comentário
    mentioned_usernames = comment.body.scan(/@(\w+)/).flatten
    mentioned_usernames.each do |username|
      user = User.find_by(username: username)
      CommentMailer.mention_notification(comment, user).deliver_later if user
    end
  end
end
```

Disparado via `after_create_commit`:

```ruby
after_create_commit :notify_async

def notify_async
  NotifyCommentJob.perform_later(self)
end
```

---

## 12. CSS — Collapse/Expand

Mantém a abordagem CSS pura do Lobsters:

```css
/* Oculta o checkbox */
.comment_folder_button {
  display: none;
}

/* Label funciona como botão de collapse */
.comment_folder:before {
  content: "[-]";
  cursor: pointer;
}

/* Quando colapsado: muda ícone e esconde conteúdo */
.comment_folder_button:checked ~ .comment_content {
  display: none;
}

.comment_folder_button:checked ~ .comment_folder:before {
  content: "[+]";
}

/* Colapsa sub-árvore inteira */
li.comments_subtree:has(> .comment > .comment_folder_button:checked) > ol.comments {
  display: none;
}

/* Indentação por profundidade */
ol.comments {
  margin-left: 24px;
  list-style: none;
  border-left: 1px dashed var(--color-border);
}
```

---

## 13. Resumo: Arquivos e Responsabilidades

```
app/
├── models/
│   ├── comment.rb              # Modelo principal + CTE + score/confidence + soft delete
│   ├── vote.rb                 # Voto (+1/-1) com cast atômico + bulk-load
│   ├── flag.rb                 # Flag de moderação
│   ├── comment_vote_hydrator.rb # Bulk-load de dados do usuário nos comentários
│   └── concerns/
│       └── commentable.rb      # Concern para modelos que aceitam comentários
├── controllers/
│   ├── comments_controller.rb  # CRUD + upvote/downvote/flag/unflag/undelete/reply
│   └── mod/
│       └── comments_controller.rb # Moderação (mod-delete, resolve flags)
├── views/comments/
│   ├── _tree.html.erb          # Renderiza árvore flat como HTML aninhado
│   ├── _comment.html.erb       # Cada comentário individual
│   ├── _actions.html.erb       # Botões de ação (reply, edit, vote, flag)
│   ├── _form.html.erb          # Formulário de novo comentário/resposta
│   ├── _reply_frame.html.erb   # Turbo Frame lazy para form de resposta
│   ├── _score.html.erb         # Exibição do score
│   ├── _gone.html.erb          # Comentário deletado/removido
│   ├── create.turbo_stream.erb # Turbo Stream após criação
│   ├── update.turbo_stream.erb # Turbo Stream após edição
│   ├── destroy.turbo_stream.erb# Turbo Stream após soft delete
│   ├── upvote.turbo_stream.erb # Turbo Stream após voto
│   ├── downvote.turbo_stream.erb
│   ├── flag.turbo_stream.erb
│   ├── unflag.turbo_stream.erb
│   └── undelete.turbo_stream.erb
├── javascript/controllers/
│   ├── comment_controller.js       # Voto otimista + collapse persist
│   ├── comment_form_controller.js  # Reset, cancel, preview do form
│   └── comments_tree_controller.js # Restaura collapse do localStorage
├── jobs/
│   └── notify_comment_job.rb      # Notificações (SolidQueue)
└── mailers/
    └── comment_mailer.rb           # Emails de notificação
```
