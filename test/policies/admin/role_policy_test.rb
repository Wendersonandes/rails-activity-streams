require "test_helper"

class Admin::RolePolicyTest < ActiveSupport::TestCase
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

  test "index? is true for site admin" do
    assert Admin::RolePolicy.new(@alice, @site_actor).index?
    assert_not Admin::RolePolicy.new(@bob, @site_actor).index?
  end

  test "update? is true for site admin" do
    assert Admin::RolePolicy.new(@alice, @site_actor).update?
    assert_not Admin::RolePolicy.new(@bob, @site_actor).update?
  end

  test "create? is true for site admin" do
    assert Admin::RolePolicy.new(@alice, @site_actor).create?
    assert_not Admin::RolePolicy.new(@bob, @site_actor).create?
  end
end
