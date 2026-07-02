require "test_helper"

class Admin::RolesControllerTest < ActionDispatch::IntegrationTest
  setup do
    seed_permissions_and_relations
    @alice = users(:alice)
    @bob = users(:bob)
    @alice_actor = create_profile_for(@alice, name: "Alice")
    @bob_actor = create_profile_for(@bob, name: "Bob")
    @alice.update!(current_profile: @alice_actor)
    @bob.update!(current_profile: @bob_actor)
    @site_actor = Site.instance.actor
    GroupMembershipService.new(@site_actor, @alice_actor).add(role: "admin")
  end

  test "admin can see roles index" do
    sign_in @alice
    get admin_roles_path
    assert_response :success
  end

  test "non-admin cannot see roles index" do
    sign_in @bob
    get admin_roles_path
    assert_response :redirect
  end

  test "admin can update a role" do
    sign_in @alice
    patch admin_role_path(@bob_actor), params: { from_role: "member", to_role: "editor" }
    assert_redirected_to admin_roles_path
    assert @site_actor.has_relation_with?(@bob_actor, "Editor")
  end

  test "non-admin cannot update a role" do
    sign_in @bob
    patch admin_role_path(@bob_actor), params: { from_role: "member", to_role: "editor" }
    assert_response :redirect
    assert_not @site_actor.has_relation_with?(@bob_actor, "Editor")
  end

  test "admin can assign a role to a user without one" do
    sign_in @alice
    post admin_roles_path, params: { actor_id: @bob_actor.slug, to_role: "moderator" }
    assert_redirected_to admin_roles_path
    assert @site_actor.has_relation_with?(@bob_actor, "Moderator")
  end

  test "assign replaces existing role instead of accumulating" do
    sign_in @alice
    GroupMembershipService.new(@site_actor, @bob_actor).add(role: "member")
    bob_actor_reloaded = Actor.find(@bob_actor.id)

    post admin_roles_path, params: { actor_id: bob_actor_reloaded.slug, to_role: "editor" }
    site_reloaded = Site.instance.actor

    assert site_reloaded.has_relation_with?(bob_actor_reloaded, "Editor")
    assert_not site_reloaded.has_relation_with?(bob_actor_reloaded, "Member")
  end
end
