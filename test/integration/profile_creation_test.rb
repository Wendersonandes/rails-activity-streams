require "test_helper"

class ProfileCreationTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
  end

  test "creates Profile, Actor, and ActivityObject in transaction" do
    assert_difference "Profile.count", 1 do
      assert_difference "Actor.count", 2 do
        assert_difference "ActivityObject.count", 1 do
          @actor = ProfileCreation.new(@alice, name: "Alice Profile").call
        end
      end
    end

    assert @actor.profile?
    profile = @actor.profile
    assert_equal @alice, profile.user
    assert_instance_of Actor, profile.actor
    assert_instance_of ActivityObject, profile.activity_object
    assert_equal "Alice Profile", profile.name
  end

  test "profile.name delegates to actor" do
    actor = create_profile_for(@alice, name: "MyName")

    assert_equal "MyName", actor.name
    assert_equal "MyName", actor.profile.name
  end

  test "actor.subject returns the profile" do
    actor = create_profile_for(@alice)

    assert_equal actor.profile, actor.subject
  end
end
