require "test_helper"

class GroupMembershipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    seed_permissions_and_relations
    @alice = users(:alice)
    @bob = users(:bob)
    @carol_user = User.create!(email: "carol@example.com", password: "password123", profile_name: "Carol")
    @alice_actor = create_profile_for(@alice, name: "Alice")
    @bob_actor = create_profile_for(@bob, name: "Bob")
    @carol_actor = @carol_user.current_profile
    @alice.update!(current_profile: @alice_actor)
    @bob.update!(current_profile: @bob_actor)
    @group = create_group_with_admin(@alice_actor)
  end

  test "should get index" do
    get group_memberships_path(@group)
    assert_response :success
  end

  test "admin can add member" do
    sign_in @alice
    assert_difference "Tie.count", 1 do
      post group_memberships_path(@group), params: { actor_id: @bob_actor.id, role: "member" }
    end
    assert_redirected_to group_memberships_path(@group)
    assert @group.actor.has_relation_with?(@bob_actor, "Member")
  end

  test "non-admin cannot add member" do
    sign_in @bob
    assert_no_difference "Tie.count" do
      post group_memberships_path(@group), params: { actor_id: @carol_actor.id, role: "member" }
    end
    assert_response :redirect
    assert_not @group.actor.has_relation_with?(@carol_actor, "Member")
  end

  test "admin can change member role" do
    sign_in @alice
    @group.actor.connect_to(@bob_actor, as: "member")

    patch group_membership_path(@group, @bob_actor), params: { from_role: "member", to_role: "moderator" }
    assert_redirected_to group_memberships_path(@group)
    assert @group.actor.has_relation_with?(@bob_actor, "Moderator")
    assert_not @group.actor.has_relation_with?(@bob_actor, "Member")
  end

  test "non-admin cannot change role" do
    sign_in @bob
    @group.actor.connect_to(@bob_actor, as: "member")

    patch group_membership_path(@group, @bob_actor), params: { from_role: "member", to_role: "moderator" }
    assert_response :redirect
    assert_not @group.actor.has_relation_with?(@bob_actor, "Moderator")
    assert @group.actor.has_relation_with?(@bob_actor, "Member")
  end

  test "admin can remove member" do
    sign_in @alice
    @group.actor.connect_to(@bob_actor, as: "member")

    assert_difference "Tie.count", -1 do
      delete group_membership_path(@group, @bob_actor), params: { role: "member" }
    end
    assert_redirected_to group_memberships_path(@group)
    assert_not @group.actor.has_relation_with?(@bob_actor, "Member")
  end

  test "member can leave group" do
    sign_in @bob
    @group.actor.connect_to(@bob_actor, as: "member")

    assert_difference "Tie.count", -1 do
      delete group_membership_path(@group, @bob_actor), params: { role: "member" }
    end
    assert_redirected_to groups_path
    assert_not @group.actor.has_relation_with?(@bob_actor, "Member")
  end

  test "non-member cannot leave group" do
    sign_in @bob

    assert_no_difference "Tie.count" do
      delete group_membership_path(@group, @bob_actor), params: { role: "member" }
    end
    assert_response :redirect
  end

  private

  def create_group_with_admin(admin_actor)
    group = Group.new
    group.build_actor(name: "Test Group Controller")
    GroupCreation.new(admin_actor, group).call
  end
end
