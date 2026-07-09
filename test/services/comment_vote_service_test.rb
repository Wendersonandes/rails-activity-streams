require "test_helper"

class CommentVoteServiceTest < ActiveSupport::TestCase
  setup do
    seed_permissions_and_relations
    @user = users(:alice)
    @actor = create_profile_for(@user)
    @bob = users(:bob)
    @bob_actor = create_profile_for(@bob)

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
    @activity.audiences.create!(relation: Relation::Public.instance)

    @comment_activity = CommentCreation.new(
      author: @actor,
      user_author: @user,
      parent_activity: @activity,
      text: "Votable comment!"
    ).call
    @comment = @comment_activity.direct_object.objectable
  end

  test "casts a downvote" do
    assert_equal 1, @comment.score

    CommentVoteService.new(
      actor: @bob_actor,
      user: @bob,
      comment_activity: @comment_activity,
      value: -1
    ).call

    assert_equal 0, @comment.reload.score
  end

  test "toggles vote (cancels identical vote)" do
    CommentVoteService.new(
      actor: @actor,
      user: @user,
      comment_activity: @comment_activity,
      value: 1
    ).call

    assert_equal 0, @comment.reload.score
  end

  test "switches vote from upvote to downvote" do
    CommentVoteService.new(
      actor: @bob_actor,
      user: @bob,
      comment_activity: @comment_activity,
      value: 1
    ).call
    assert_equal 2, @comment.reload.score

    CommentVoteService.new(
      actor: @bob_actor,
      user: @bob,
      comment_activity: @comment_activity,
      value: -1
    ).call
    assert_equal 0, @comment.reload.score
  end
end
