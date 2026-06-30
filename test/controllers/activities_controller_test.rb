require "test_helper"

class ActivitiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    seed_permissions_and_relations
    @user = users(:alice)
    @actor = create_profile_for(@user)

    @user.update!(current_profile: @actor)
    sign_in @user
  end

  test "should redirect index when not signed in" do
    sign_out @user
    get activities_path
    assert_redirected_to new_user_session_path
  end

  test "should get index when signed in" do
    get activities_path
    assert_response :success
  end

  test "should redirect new when not signed in" do
    sign_out @user
    get new_activity_path
    assert_redirected_to new_user_session_path
  end

  test "should get new when signed in" do
    get new_activity_path
    assert_response :success
  end

  test "should create post activity" do
    post activities_path, params: {
      activity: {
        verb: :post,
        text: { title: "Hello world", body: "My first post" }
      }
    }
    assert_redirected_to activity_path(Activity.last)
    assert_equal "Post created.", flash[:notice]
  end

  test "should destroy own activity" do
    activity = Activity.create!(verb: :post, author: @actor, owner: @actor,
                                user_author: @user)
    activity.audiences.create!(relation: Relation::Public.instance)

    assert_difference("Activity.count", -1) do
      delete activity_path(activity)
    end
    assert_redirected_to activities_path
  end

  test "should not destroy others activity" do
    bob = create_profile_for(users(:bob))
    activity = Activity.create!(verb: :post, author: bob, owner: bob,
                                user_author: users(:bob))
    activity.audiences.create!(relation: Relation::Public.instance)

    assert_no_difference("Activity.count") do
      delete activity_path(activity)
    end
    assert_redirected_to root_path
  end
end
