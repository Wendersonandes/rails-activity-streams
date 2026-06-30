require "test_helper"

# == Schema Information
#
# Table name: groups
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class GroupTest < ActiveSupport::TestCase
  test "responds to actor association" do
    group = Group.new
    assert_respond_to group, :actor
    assert_respond_to group, :build_actor
  end

  test "has no user association" do
    group = Group.new
    assert_not group.respond_to?(:user)
  end

  test "delegates name to actor" do
    actor = Actor.new(name: "Test Group Name")
    group = Group.new
    group.build_actor(actorable: group, name: "Test Group Name")
    assert_equal "Test Group Name", group.name
  end
end
