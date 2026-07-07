# Plano de Implementação: Posts de Perfis em Grupos

Permitir que usuários (através de seus `Profiles`) criem publicações (`Posts`) diretamente nos murais dos `Groups` dos quais fazem parte, seguindo a arquitetura orientada a grafos do padrão Activity Streams e do framework Social Stream.

## User Review Required

> [!IMPORTANT]
> **Permissão Padrão de Membros:** Este plano altera a configuração padrão do Social Stream no arquivo `social_stream.rb` para adicionar a permissão `[ "create", "activity" ]` à relação de `"member"`. Isso significa que, por padrão, qualquer membro adicionado a um grupo terá permissão para postar no mural desse grupo.

> [!NOTE]
> **Exibição do Feed do Grupo:** A listagem de atividades no `GroupsController#show` será modificada de `where(author: @group.actor)` para `owned_by(@group.actor)`. Isso fará com que a página do grupo exiba tanto posts criados pelo grupo em si quanto posts criados por membros *dentro* do grupo.

## Proposed Changes

---

### Configuração

#### [MODIFY] [social_stream.rb](file:///Users/wenderson/Sites/Rails/social_stream_lab/social_stream_app/config/initializers/social_stream.rb)
- Adicionar a permissão `[ "create", "activity" ]` na relação de `"member"` dentro do escopo de `"group"`.

---

### Políticas de Autorização (Policies)

#### [MODIFY] [activity_policy.rb](file:///Users/wenderson/Sites/Rails/social_stream_lab/social_stream_app/app/policies/activity_policy.rb)
- Ajustar o método `create?` para verificar se o `owner` (quando diferente do `author`) permite que o `author` crie atividades:
  `record.owner.relations.allow?(record.author, :create, :activity)`.

---

### Controllers

#### [MODIFY] [activities_controller.rb](file:///Users/wenderson/Sites/Rails/social_stream_lab/social_stream_app/app/controllers/activities_controller.rb)
- Permitir o parâmetro `:owner_id` nos `activity_params`.
- Ajustar a criação da `Activity` no método `create` para definir o `owner` com base no `owner_id` recebido (caso presente), mantendo o fallback para `current_actor`.

#### [MODIFY] [groups_controller.rb](file:///Users/wenderson/Sites/Rails/social_stream_lab/social_stream_app/app/controllers/groups_controller.rb)
- Ajustar a query de `@activities` no método `show` para carregar as atividades usando o escopo `owned_by(@group.actor)` ao invés de filtrar por `author`.

---

### Views

#### [MODIFY] [show.html.erb](file:///Users/wenderson/Sites/Rails/social_stream_lab/social_stream_app/app/views/groups/show.html.erb)
- Extrair ou incluir um formulário de criação de post (`_form`) na página do grupo, visível apenas para membros (`@is_member`), enviando o ID do grupo como campo oculto `owner_id`.

#### [NEW] [activity_policy_test.rb](file:///Users/wenderson/Sites/Rails/social_stream_lab/social_stream_app/test/policies/activity_policy_test.rb)
- Criar testes para validar a `ActivityPolicy` cobrindo:
  - Membro do grupo tem permissão de criação.
  - Não membro tem permissão de criação negada.

#### [MODIFY] [activities_controller_test.rb](file:///Users/wenderson/Sites/Rails/social_stream_lab/social_stream_app/test/controllers/activities_controller_test.rb)
- Adicionar testes de integração cobrindo:
  - Criação de post no grupo com sucesso por um membro.
  - Tentativa frustrada de postagem por um não membro (gerando erro de autorização).

## Verification Plan

### Automated Tests
Executar a suíte de testes de policies, controllers e models relevantes:
- `bin/rails test test/policies/activity_policy_test.rb`
- `bin/rails test test/controllers/activities_controller_test.rb`
- `bin/rails test test/controllers/groups_controller_test.rb`

### Manual Verification
- Iniciar o servidor Rails local.
- Fazer login com o usuário `Bob` (membro do grupo) e navegar até o grupo.
- Verificar se o formulário de novo post é exibido.
- Escrever um post e publicá-lo, garantindo que ele aparece no feed do grupo.
- Fazer login com o usuário `Carol` (não membro do grupo) e certificar que o formulário de postagem no grupo não é exibido.
