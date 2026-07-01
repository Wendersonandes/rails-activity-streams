require "test_helper"

class ActorTest < ActiveSupport::TestCase
  setup do
    seed_permissions_and_relations
    @alice = users(:alice)
    @bob = users(:bob)
    @carol_user = User.create!(email: "carol@example.com", password: "password123", profile_name: "Carol")
    @alice_actor = create_profile_for(@alice, name: "Alice")
    @bob_actor = create_profile_for(@bob, name: "Bob")
    @carol_actor = @carol_user.current_profile
    @group = create_group_with_admin(@alice_actor)
  end

  test "has_relation_with? returns true for connected actor with matching relation" do
    @group.actor.connect_to(@bob_actor, as: "member")
    assert @group.actor.has_relation_with?(@bob_actor, "Member")
    assert_not @group.actor.has_relation_with?(@bob_actor, "Admin")
  end

  test "has_relation_with? returns false for unconnected actor" do
    assert_not @group.actor.has_relation_with?(@carol_actor, "Member")
  end

  test "disconnect_from removes specific relation tie" do
    @group.actor.connect_to(@bob_actor, as: "member")
    assert_difference "Tie.count", -1 do
      @group.actor.disconnect_from(@bob_actor, "member")
    end
    assert_not @group.actor.has_relation_with?(@bob_actor, "Member")
  end

  test "disconnect_from does nothing if relation does not exist" do
    assert_no_difference "Tie.count" do
      @group.actor.disconnect_from(@carol_actor, "member")
    end
  end

  test "member_roles_for returns all roles for a connected actor" do
    @group.actor.connect_to(@bob_actor, as: "member")
    roles = @group.actor.member_roles_for(@bob_actor)
    assert_includes roles, "member"
    assert_not_includes roles, "admin"
  end

  test "member_roles_for returns empty array for unconnected actor" do
    roles = @group.actor.member_roles_for(@carol_actor)
    assert_empty roles
  end

  test "connect_to with multiple relations creates separate ties" do
    @group.actor.connect_to(@bob_actor, as: "member")
    assert_difference "Tie.count", 1 do
      @group.actor.connect_to(@bob_actor, as: "moderator")
    end
    roles = @group.actor.member_roles_for(@bob_actor)
    assert_includes roles, "member"
    assert_includes roles, "moderator"
  end

  private

  def create_group_with_admin(admin_actor)
    group = Group.new
    group.build_actor(name: "Test Group")
    GroupCreation.new(admin_actor, group).call
  end
end
