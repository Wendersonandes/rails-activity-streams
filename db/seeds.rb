puts "Seeding Social Stream core..."

# ── Permissions & System Relations ──────────────────────────────
permissions = Permission.instances([
  [ :create, :activity ],
  [ :read,   :activity ],
  [ :update, :activity ],
  [ :destroy, :activity ],
  [ :follow, nil ],
  [ :represent, nil ]
])
puts "  Permissions: #{permissions.size} created"

public_rel = Relation::Public.instance
follow_rel = Relation::Follow.instance
reject_rel = Relation::Reject.instance
puts "  Relations: Public(#{public_rel.id}) Follow(#{follow_rel.id}) Reject(#{reject_rel.id})"

# ── Users & Profiles ────────────────────────────────────────────
puts "\nCreating users & profiles..."

users_data = [
  { email: "ana@example.com",   name: "Ana Silva" },
  { email: "bruno@example.com", name: "Bruno Costa" },
  { email: "carla@example.com", name: "Carla Mendes" },
  { email: "diego@example.com", name: "Diego Rocha" },
  { email: "elisa@example.com", name: "Elisa Torres" }
]

users = {}
users_data.each do |data|
  user = User.find_or_initialize_by(email: data[:email])
  if user.new_record?
    user.password = "password123"
    user.profile_name = data[:name]
    user.save!
  end
  users[data[:name].split.first.downcase.to_sym] = user
  puts "  #{data[:name]} (#{data[:email]}) — profile: #{user.current_profile&.name}"
end

actors = users.transform_values { |u| u.current_profile }

# ── Site & Global Roles ────────────────────────────────────────
puts "\nSetting up global roles..."
site_actor = Site.instance.actor
GroupMembershipService.new(site_actor, actors[:ana]).add(role: "admin")
puts "  Site: #{Site.instance.name}, Admin: Ana"

# ── Groups ──────────────────────────────────────────────────────
puts "\nCreating groups..."

def create_group(name:, description:, creator:, privacy: :public_group)
  group = Group.new
  group.build_actor(name: name, description: description)
  group.privacy = privacy.to_s
  GroupCreation.new(creator, group).call
end

groups = {}

groups[:dev] = create_group(
  name: "Dev Team",
  description: "Engineering squad — code, deploy, review.",
  creator: actors[:ana]
)
puts "  Dev Team (admin: Ana)"

groups[:design] = create_group(
  name: "Design Circle",
  description: "UI/UX discussions, design critiques, and inspiration.",
  creator: actors[:bruno],
  privacy: :private_group
)
puts "  Design Circle (admin: Bruno, private)"

groups[:mkt] = create_group(
  name: "Marketing Hub",
  description: "Campaigns, analytics, and growth strategies.",
  creator: actors[:carla]
)
puts "  Marketing Hub (admin: Carla)"

# ── Memberships — Dev Team ──────────────────────────────────────
puts "\nEstablishing memberships..."

def add_member(group, user, role: "member")
  group.actor.connect_to(user, as: role)
  user.connect_to(group.actor, as: "member")
end

# Dev Team: Ana(admin), Bruno(mod), Carla(mod), Diego(member), Elisa(member)
add_member(groups[:dev], actors[:bruno], role: "moderator")
add_member(groups[:dev], actors[:carla], role: "moderator")
add_member(groups[:dev], actors[:diego])
add_member(groups[:dev], actors[:elisa])
puts "  Dev Team: +Bruno(mod) +Carla(mod) +Diego(member) +Elisa(member)"

# Design Circle: Bruno(admin), Ana(member), Carla(member), Elisa(member)
add_member(groups[:design], actors[:ana])
add_member(groups[:design], actors[:carla])
add_member(groups[:design], actors[:elisa])
puts "  Design Circle: +Ana(member) +Carla(member) +Elisa(member)"

# Marketing Hub: Carla(admin), Diego(mod), Ana(member), Bruno(member)
add_member(groups[:mkt], actors[:diego], role: "moderator")
add_member(groups[:mkt], actors[:ana])
add_member(groups[:mkt], actors[:bruno])
puts "  Marketing Hub: +Diego(mod) +Ana(member) +Bruno(member)"

# ── Contacts (profile-to-profile follows) ───────────────────────
puts "\nCreating contacts..."
actors[:ana].connect_to(actors[:bruno], as: "friend")
actors[:ana].connect_to(actors[:carla], as: "friend")
actors[:bruno].connect_to(actors[:diego], as: "colleague")
actors[:carla].connect_to(actors[:elisa], as: "friend")
actors[:diego].connect_to(actors[:ana],   as: "acquaintance")
actors[:elisa].connect_to(actors[:bruno], as: "acquaintance")
actors[:elisa].connect_to(actors[:carla], as: "colleague")
puts "  7 contacts created"

# ── Activities / Posts ──────────────────────────────────────────
puts "\nCreating posts..."

def create_post(author:, owner:, title:, body: "")
  activity = Activity.new(verb: :post, author: author, owner: owner)
  activity.user_author = author.subject.is_a?(Profile) ? author.subject.user : nil
  ActivityCreation.new(
    activity,
    text: { title: title, body: body },
    relation_ids: owner.activity_relation_ids
  ).call
end

# Dev Team posts
create_post(
  author: actors[:ana],   owner: groups[:dev].actor,
  title: "Boas-vindas!",
  body: "Primeiro post do time! Bem-vindos ao Dev Team. Vamos usar este espaço pra compartilhar novidades e discutir PRs."
)
create_post(
  author: actors[:bruno], owner: groups[:dev].actor,
  title: "Turbo 8 — alguém testou?",
  body: "Alguém já testou o novo Turbo 8? Parece que o morphing está muito mais rápido agora."
)
create_post(
  author: actors[:carla], owner: groups[:dev].actor,
  title: "PR aberto — pipeline de CI",
  body: "Acabei de abrir um PR com a refatoração do pipeline de CI. Reviews são bem-vindos!"
)
create_post(
  author: actors[:diego], owner: groups[:dev].actor,
  title: "Bug no worker de emails",
  body: "Bug encontrado no worker de emails. Já estou trabalhando na correção, abro PR em 1h."
)

# Design Circle posts
create_post(
  author: actors[:bruno], owner: groups[:design].actor,
  title: "Critique rounds — toda sexta",
  body: "Postem aqui os designs que vocês estão trabalhando esta semana. Vamos fazer critique rounds toda sexta."
)
create_post(
  author: actors[:carla], owner: groups[:design].actor,
  title: "Referência: grid de 8px",
  body: "Referência interessante no Dribbble — composição com grid de 8px que ficou muito limpa."
)
create_post(
  author: actors[:elisa], owner: groups[:design].actor,
  title: "Design system quase pronto",
  body: "Novo design system está quase pronto. Componentes de formulário e data table já estão no Figma."
)

# Marketing Hub posts
create_post(
  author: actors[:carla], owner: groups[:mkt].actor,
  title: "Resultados da campanha de Junho",
  body: "Resultados da campanha de Junho: 12% crescimento orgânico. Vamos discutir na reunião de amanhã."
)
create_post(
  author: actors[:diego], owner: groups[:mkt].actor,
  title: "Dashboard no Metabase",
  body: "Configurei o dashboard de analytics no Metabase. Quem quiser acesso, me avisa."
)

# Personal wall posts
create_post(
  author: actors[:ana], owner: actors[:ana],
  title: "Animada!",
  body: "Acabei de entrar em 3 grupos! Animada pra colaborar com o time 😊"
)
create_post(
  author: actors[:bruno], owner: actors[:bruno],
  title: "Design Circle",
  body: "Design Circle está crescendo. Se você curte UI/UX, cola lá!"
)

puts "  11 posts created"

# ── Comments ────────────────────────────────────────────────────
puts "\nCreating comments..."

def create_comment(author:, parent_activity:, text:)
  user_author = author.subject.is_a?(Profile) ? author.subject.user : nil
  CommentCreation.new(
    author: author,
    user_author: user_author,
    parent_activity: parent_activity,
    text: text
  ).call
end

# Find posts by their titles
posts = Activity.where(verb: :post).to_a
welcome_post      = posts.find { |p| p.direct_object&.title&.include?("Boas-vindas") }
turbo_post        = posts.find { |p| p.direct_object&.title&.include?("Turbo 8") }
ci_pr_post        = posts.find { |p| p.direct_object&.title&.include?("PR aberto") }
campaign_post     = posts.find { |p| p.direct_object&.title&.include?("Resultados") }
animada_post      = posts.find { |p| p.direct_object&.title&.include?("Animada") }

initial_activity_count = Activity.count

# ── Dev Team: Boas-vindas! ──
c1 = create_comment(
  author: actors[:bruno],
  parent_activity: welcome_post,
  text: "Bem-vinda, Ana! Ótimo termos esse espaço. Vai facilitar muito a comunicação do time."
)

c2 = create_comment(
  author: actors[:carla],
  parent_activity: welcome_post,
  text: "Isso mesmo! Finalmente um lugar organizado pra gente discutir código sem poluir o chat."
)

# Reply to Bruno's comment (depth 1 → 2)
c3 = create_comment(
  author: actors[:ana],
  parent_activity: c1,
  text: "Obrigada, Bruno! A ideia é manter tudo aqui mesmo — decisões, PRs, discussões técnicas."
)

c4 = create_comment(
  author: actors[:diego],
  parent_activity: c1,
  text: "Apoiado! Já vou migrar as discussões técnicas do WhatsApp pra cá."
)

# Reply to Diego's reply (depth 2 → 3)
create_comment(
  author: actors[:bruno],
  parent_activity: c4,
  text: "Boa, Diego! WhatsApp é um buraco negro de informação. Aquilo some em 2 dias."
)

# ── Dev Team: Turbo 8 ──
create_comment(
  author: actors[:ana],
  parent_activity: turbo_post,
  text: "Testei sim! O morphing realmente deu um salto. O cache de página inteira ficou muito mais esperto."
)

c5 = create_comment(
  author: actors[:elisa],
  parent_activity: turbo_post,
  text: "Ainda não testei, mas li o changelog. A parte de stream updates paralelos me chamou atenção."
)

# Reply to Elisa's comment
create_comment(
  author: actors[:bruno],
  parent_activity: c5,
  text: "Sim! Dá pra fazer broadcast de Turbo Stream de múltiplas origens agora. Vou preparar uma demo."
)

# ── Dev Team: PR aberto ──
c6 = create_comment(
  author: actors[:diego],
  parent_activity: ci_pr_post,
  text: "Bacana, Carla! Dei uma olhada no PR. A separação dos stages ficou muito mais clara."
)

# Reply to Diego
create_comment(
  author: actors[:carla],
  parent_activity: c6,
  text: "Valeu! Ainda quero adicionar cache dos estágios que não mudaram. Mas já está funcional."
)

# ── Marketing Hub: Resultados ──
c7 = create_comment(
  author: actors[:diego],
  parent_activity: campaign_post,
  text: "12% orgânico é um número excelente! Qual canal teve melhor performance?"
)

# Reply to Diego
create_comment(
  author: actors[:carla],
  parent_activity: c7,
  text: "LinkedIn surpreendeu — 8% dos 12% vieram de orgânico lá. Vamos dobrar a frequência de posts."
)

# ── Personal: Animada! ──
create_comment(
  author: actors[:bruno],
  parent_activity: animada_post,
  text: "Que bom te ver engajada, Ana! A plataforma fica muito melhor com todo mundo participando."
)

create_comment(
  author: actors[:carla],
  parent_activity: animada_post,
  text: "Verdade! E os grupos estão bem ativos. Design Circle já tem discussões muito boas."
)

comment_count = Activity.count - initial_activity_count
puts "  #{comment_count} comment activities created"

# ── Summary ─────────────────────────────────────────────────────
puts "\n#{'='*60}"
puts "Seed complete!"
puts "#{'='*60}"
puts "  Users:     #{User.count} (#{Profile.count} profiles)"
puts "  Groups:    #{Group.count}"
puts "  Actors:    #{Actor.count}"
puts "  Contacts:  #{Contact.count}"
puts "  Ties:      #{Tie.count}"
puts "  Activities: #{Activity.count}"
puts "  Relations: #{Relation::Custom.count} custom"
puts "#{'='*60}"
puts "\nLogin with any email above, password: password123"
puts "Try: http://localhost:3000/groups/#{groups[:dev].actor.slug}"
