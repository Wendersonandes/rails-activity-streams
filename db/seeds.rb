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

# Dev Team: Ana(admin), Bruno(mod), Carla(mod), Diego(member), Elisa(member)
groups[:dev].actor.connect_to(actors[:bruno], as: "moderator")
groups[:dev].actor.connect_to(actors[:carla], as: "moderator")
groups[:dev].actor.connect_to(actors[:diego], as: "member")
groups[:dev].actor.connect_to(actors[:elisa], as: "member")
puts "  Dev Team: +Bruno(mod) +Carla(mod) +Diego(member) +Elisa(member)"

# Design Circle: Bruno(admin), Ana(member), Carla(member), Elisa(member)
groups[:design].actor.connect_to(actors[:ana],   as: "member")
groups[:design].actor.connect_to(actors[:carla], as: "member")
groups[:design].actor.connect_to(actors[:elisa], as: "member")
puts "  Design Circle: +Ana(member) +Carla(member) +Elisa(member)"

# Marketing Hub: Carla(admin), Diego(mod), Ana(member), Bruno(member)
groups[:mkt].actor.connect_to(actors[:diego], as: "moderator")
groups[:mkt].actor.connect_to(actors[:ana],   as: "member")
groups[:mkt].actor.connect_to(actors[:bruno], as: "member")
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
