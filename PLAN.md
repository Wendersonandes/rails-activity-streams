# @mentions Feature Plan

## Visão Geral

Permitir que usuários mencionem outros perfis em posts e comentários usando a sintaxe
`@[Nome do Profile](slug)`. O sistema detecta, armazena referências, renderiza links
clicáveis e notifica os mencionados.

---

## Arquitetura

```
┌──────────────┐     ┌─────────────────┐     ┌──────────────┐
│  Post/Comment │────▶│  MentionCreator  │────▶│   Mention    │
│  (raw text)   │     │  (after save)    │     │   (DB)       │
└──────────────┘     └─────────────────┘     └──────┬───────┘
                                                    │
┌──────────────┐     ┌─────────────────┐            │
│  View render │◀────│ render_with_    │◀───────────┘
│  (HTML)      │     │ mentions(helper)│  (lookup actors)
└──────────────┘     └─────────────────┘
```

---

## Sintaxe de menção

```
@[Nome do Profile](slug)
```

Exemplos:
- `@[Ana Silva](ana-silva)` → link para `/profiles/ana-silva`
- `@[Dev Team](dev-team)` → link para `/groups/dev-team`

O nome é exibido, o slug garante unicidade na resolução.

---

## Componentes

| Componente | Arquivo | Responsabilidade |
|---|---|---|
| **Mention** (model) | `app/models/mention.rb` | `activity_object_id` + `actor_id`. Unique index. |
| **Migration** | `db/migrate/xxx_create_mentions.rb` | Tabela `mentions` |
| **MentionCreator** (service) | `app/services/mention_creator.rb` | Parse do texto, cria Mention records, dispara notificações |
| **render_with_mentions** (helper) | `app/helpers/mentions_helper.rb` | Escapa HTML, converte `@[Name](slug)` em `<a>` links, retorna html_safe |
| **ActorMentionedNotifier** | `app/notifiers/actor_mentioned_notifier.rb` | Notifica ator mencionado via sistema `noticed` |
| **Actors search endpoint** | `app/controllers/actors_controller.rb#search` | `GET /actors/search?q=...` — retorna JSON com name, slug, avatar_url |
| **mention_controller.js** | `app/javascript/controllers/mention_controller.js` | Stimulus + Tribute.js: autocomplete com nome e avatar |

---

## Tabela `mentions`

| Coluna | Tipo | Notas |
|---|---|---|
| `id` | bigint | PK |
| `activity_object_id` | bigint | FK → activity_objects, NOT NULL |
| `actor_id` | bigint | FK → actors (mencionado), NOT NULL |
| `timestamps` | | |

Unique index em `[activity_object_id, actor_id]`.

---

## Fluxo de criação

1. Usuário digita no textarea: `"Olha isso @[Bruno Costa](bruno-costa)"`
2. `ActivityCreation#call` ou `CommentCreation#call` salva o texto cru em `activity_objects.description`
3. `MentionCreator.new(activity_object).call`:
   - Escaneia o texto com regex `/@\[([^\]]+)\]\(([\w-]+)\)/`
   - Para cada match, busca `Actor.find_by(slug:)`
   - Se o ator existe e não é o autor → `Mention.create!(activity_object:, actor:)`
   - Dispara `ActorMentionedNotifier.with(mention:).deliver_later(actor)`

---

## Fluxo de renderização

### Posts (`_activity.html.erb`)
```erb
<%= render_with_mentions(ao.description) %>
```

### Comentários (`_comment.html.erb`)
```erb
<%= simple_format(render_with_mentions(comment.text), {}, sanitize: false) %>
```
`sanitize: false` é necessário porque `simple_format` sanitiza por padrão.
O helper já escapa todo o HTML antes de injetar os links, então é seguro.

---

## Tribute.js — autocomplete

### Endpoint
```
GET /actors/search?q=Ana
→ [
    { name: "Ana Silva", slug: "ana-silva", avatar_url: "/rails/active_storage/...", type: "Profile" },
    { name: "Dev Team", slug: "dev-team", avatar_url: null, type: "Group" }
  ]
```

### Stimulus controller
```js
// mention_controller.js
import { Controller } from "@hotwired/stimulus"
import Tribute from "tributejs"

export default class extends Controller {
  connect() {
    this.tribute = new Tribute({
      values: (text, cb) => {
        fetch(`/actors/search?q=${encodeURIComponent(text)}`)
          .then(r => r.json())
          .then(results => cb(results.map(u => ({
            key: u.name,
            value: `@[${u.name}](${u.slug})`,
            avatar: u.avatar_url
          }))))
      },
      lookup: "key",
      fillAttr: "value",
      requireLeadingSpace: true,
      allowSpaces: true,
      menuItemTemplate: (item) => {
        return `<div class="flex items-center gap-2 p-2">
          <img src="${item.original.avatar}" class="w-6 h-6 rounded-full" onerror="this.style.display='none'" />
          <span class="text-sm font-medium">${item.original.key}</span>
          <span class="text-xs text-gray-400">@${item.original.value.match(/\(([^)]+)\)/)?.[1]}</span>
        </div>`
      }
    })
    this.tribute.attach(this.element)
  }

  disconnect() {
    this.tribute.detach(this.element)
  }
}
```

### Form integration
```erb
<%= f.text_area :body, data: { controller: "mention" } %>
```

---

## Edge cases

| Caso | Comportamento |
|---|---|
| `@[Inexistente](slug-nao-existe)` | Mantém texto como está, não cria menção |
| Auto-menção | Não cria menção nem notificação |
| Menção duplicada no mesmo texto | Só cria 1 Mention (unique index) |
| Texto vazio/nil | `render_with_mentions` retorna `""` |
| Actor deletado após menção | Mention permanece (FK restrict), link quebra graciosamente |
| Slug com caracteres especiais | Regex `[\w-]` captura apenas válidos |

---

## Implementação (ordem)

1. Migration: `mentions` table
2. Model: `Mention`
3. Service: `MentionCreator`
4. Helper: `render_with_mentions`
5. Integrar em `ActivityCreation` e `CommentCreation`
6. Atualizar views: `_activity.html.erb`, `_comment.html.erb`
7. Notifier: `ActorMentionedNotifier`
8. Endpoint: `GET /actors/search`
9. Stimulus: `mention_controller.js` + Tribute.js
10. Testes
11. Seed: adicionar algumas menções nos posts/comentários existentes
