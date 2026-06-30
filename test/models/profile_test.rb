require "test_helper"

class ProfileTest < ActiveSupport::TestCase
  test "validates presence of user" do
    profile = Profile.new
    assert_not profile.valid?
    assert_includes profile.errors[:user], "must exist"
  end

  test "delegates name to actor" do
    alice = users(:alice)
    actor = create_profile_for(alice, name: "Alice Profile")
    profile = actor.profile

    assert_equal "Alice Profile", profile.name
    assert_equal alice, profile.user
  end

  test "ProfileCreation creates Actor and ActivityObject in transaction" do
    alice = users(:alice)

    assert_difference [ "Actor.count", "ActivityObject.count", "Profile.count" ], 1 do
      @actor = ProfileCreation.new(alice, name: "Alice").call
    end

    assert @actor.persisted?
    assert @actor.profile?
    assert_not_nil @actor.activity_object
    assert_equal "Alice", @actor.activity_object.title
  end
end
