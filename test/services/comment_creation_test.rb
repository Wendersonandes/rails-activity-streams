require "test_helper"

class CommentCreationTest < ActiveSupport::TestCase
  setup do
    seed_permissions_and_relations
    @user = users(:alice)
    @actor = create_profile_for(@user)
    
    @post = Post.new
    @post.build_activity_object(
      description: "My first post",
      author: @actor,
      user_author: @user,
      owner: @actor
    )
    @post.save!

    @activity = Activity.new(
      verb: :post,
      author: @actor,
      user_author: @user,
      owner: @actor
    )
    @activity.activity_objects << @post.activity_object
    @activity.save!
  end

  test "creates comment activity and comment object" do
    assert_difference -> { Comment.count } => 1 do
      CommentCreation.new(
        author: @actor,
        user_author: @user,
        parent_activity: @activity,
        text: "Nice post!"
      ).call
    end

    comment_activity = Activity.find_by(parent_id: @activity.id)
    assert_not_nil comment_activity
    
    comment_ao = comment_activity.direct_object
    assert_not_nil comment_ao
    assert_equal "Comment", comment_ao.objectable_type
    
    comment = comment_ao.objectable
    assert_equal "Nice post!", comment.text
    assert_equal 1, comment.score
    assert_equal 1, @activity.direct_object.reload.comment_count
  end

  test "correctly nests replies and increases depth" do
    comment_activity = CommentCreation.new(
      author: @actor,
      user_author: @user,
      parent_activity: @activity,
      text: "Nice post!"
    ).call

    reply_activity = CommentCreation.new(
      author: @actor,
      user_author: @user,
      parent_activity: comment_activity,
      text: "Nice reply!"
    ).call

    assert_equal comment_activity.id, reply_activity.parent_id
    assert_equal 1, reply_activity.direct_object.objectable.depth
  end
end
