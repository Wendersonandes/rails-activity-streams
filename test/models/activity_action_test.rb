require "test_helper"

class ActivityActionTest < ActiveSupport::TestCase
  setup do
    seed_permissions_and_relations
    @alice = users(:alice)
    @bob = users(:bob)
    @actor1 = create_profile_for(@alice)
    @actor2 = create_profile_for(@bob)
  end

  test "validates unique actor+activity_object pair" do
    obj = @actor1.activity_object
    ActivityAction.create!(actor: @actor1, activity_object: obj)

    duplicate = ActivityAction.new(actor: @actor1, activity_object: obj)
    assert_raises ActiveRecord::RecordNotUnique do
      duplicate.save(validate: false)
    end
  end

  test "#follow! toggles follow flag" do
    obj = @actor2.activity_object
    action = ActivityAction.create!(actor: @actor1, activity_object: obj, follow: false)

    action.follow!
    assert action.reload.follow

    action.unfollow!
    assert_not action.reload.follow
  end

  test ".followed scope returns only actions with follow true" do
    obj1 = @actor1.activity_object
    obj2 = @actor2.activity_object
    ActivityAction.create!(actor: @actor1, activity_object: obj1, follow: true)
    ActivityAction.create!(actor: @actor1, activity_object: obj2, follow: false)

    assert_equal 1, ActivityAction.followed.count
  end
end
