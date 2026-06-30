require "test_helper"

class ActivityObjectTest < ActiveSupport::TestCase
  setup do
    seed_permissions_and_relations
    @alice = users(:alice)
    @bob = users(:bob)
    @actor = create_profile_for(@alice)
    @bob_actor = create_profile_for(@bob)
    @ao = @actor.activity_object
  end

  test "validates presence of objectable_type" do
    ao = ActivityObject.new(objectable_id: 1)
    assert_not ao.valid?
  end

  test "delegated_type exposes objectable" do
    assert @ao.profile?
    assert_instance_of Profile, @ao.profile
  end

  test "#authored_or_owned_by? returns true for author" do
    @ao.update!(author: @actor)
    assert @ao.authored_or_owned_by?(@actor)
  end

  test "#authored_or_owned_by? returns false for unrelated actor" do
    assert_not @ao.authored_or_owned_by?(@bob_actor)
  end

  test "#acts_as_actor? returns true for Profile type" do
    assert @ao.acts_as_actor?
  end

  test "#object returns objectable" do
    assert_equal @actor.profile, @ao.object
  end

  test ".shared_with returns visible objects" do
    ActivityObjectAudience.create!(activity_object: @ao, relation: Relation::Public.instance)
    assert_includes ActivityObject.shared_with(@actor), @ao
  end
end
