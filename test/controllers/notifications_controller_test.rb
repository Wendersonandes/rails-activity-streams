require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  include ActionCable::TestHelper
  include ActiveJob::TestHelper

  setup do
    seed_permissions_and_relations
    @user = users(:alice)
    @actor = create_profile_for(@user)
    @user.update!(current_profile: @actor)

    @bob_user = users(:bob)
    @bob_actor = create_profile_for(@bob_user)
    @bob_user.update!(current_profile: @bob_actor)

    sign_in @user

    # Create a post as Bob to trigger a notification
    @post = Post.new
    @post.build_activity_object(
      title: "",
      description: "Bob's status update",
      author: @bob_actor,
      user_author: @bob_user,
      owner: @bob_actor
    )
    @post.save!
    @post_activity_object = @post.activity_object

    # Establish Alice following Bob
    ActivityAction.create!(actor: @actor, activity_object: @bob_actor.activity_object, follow: true)

    # Bob publishes a post, which triggers a notification to Alice (@actor)
    @post_activity = Activity.new(
      verb: :post,
      author: @bob_actor,
      owner: @bob_actor,
      user_author: @bob_user
    )
    @post_activity = ActivityCreation.new(@post_activity, text: { body: "Alice should get this" }).call
    
    @notification = @actor.notifications.last
  end

  test "should redirect index when not signed in" do
    sign_out @user
    get notifications_path
    assert_redirected_to new_user_session_path
  end

  test "should get index" do
    get notifications_path
    assert_response :success
    assert_select "h1", "Notifications"
    assert_includes response.body, "bob publicou um novo post."
  end

  test "should mark notification as read" do
    assert @notification.unread?
    patch notification_path(@notification)
    assert_redirected_to notifications_path
    assert @notification.reload.read?
  end

  test "should mark notification as read via turbo stream" do
    assert @notification.unread?
    patch notification_path(@notification), as: :turbo_stream
    assert_response :success
    assert @notification.reload.read?
    assert_match /turbo-stream action="replace" target="post_published_notifier_notification_#{@notification.id}"/, response.body
    assert_match /turbo-stream action="replace" target="nav_notification_badge"/, response.body
  end

  test "should mark all notifications as read" do
    # Create another notification by Bob
    activity2 = Activity.new(
      verb: :post,
      author: @bob_actor,
      owner: @bob_actor,
      user_author: @bob_user
    )
    ActivityCreation.new(activity2, text: { body: "Alice should get this too" }).call

    assert_equal 2, @actor.notifications.unread.count

    post mark_all_as_read_notifications_path
    assert_redirected_to notifications_path
    assert_equal 0, @actor.notifications.unread.count
  end

  test "should mark all notifications as read via turbo stream" do
    post mark_all_as_read_notifications_path, as: :turbo_stream
    assert_response :success
    assert_equal 0, @actor.notifications.unread.count
    assert_match /turbo-stream action="replace" target="notifications_list_container"/, response.body
    assert_match /turbo-stream action="replace" target="nav_notification_badge"/, response.body
  end

  test "should not mark others notification as read" do
    # Try to mark Alice's notification as read as Bob
    sign_out @user
    sign_in @bob_user

    patch notification_path(@notification)
    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
    assert @notification.reload.unread?
  end

  test "should broadcast badge update on notification creation" do
    stream_name = Turbo::StreamsChannel.send(:stream_name_from, [@actor, :notifications])
    assert_broadcasts(stream_name, 1) do
      perform_enqueued_jobs do
        activity = Activity.new(
          verb: :post,
          author: @bob_actor,
          owner: @bob_actor,
          user_author: @bob_user
        )
        ActivityCreation.new(activity, text: { body: "Broadcast check" }).call
      end
    end
  end

  test "should broadcast badge update on notification update" do
    stream_name = Turbo::StreamsChannel.send(:stream_name_from, [@actor, :notifications])
    assert_broadcasts(stream_name, 1) do
      @notification.mark_as_read
    end
  end
end
