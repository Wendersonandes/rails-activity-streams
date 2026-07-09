require "test_helper"

class CommentTest < ActiveSupport::TestCase
  setup do
    seed_permissions_and_relations
    @user = users(:alice)
    @actor = create_profile_for(@user)
    
    # Create a parent activity to comment on
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

  test "should generate short_id before creation" do
    comment = Comment.new
    comment.build_activity_object(
      description: "Hello test",
      author: @actor,
      user_author: @user,
      owner: @actor
    )
    comment.save!

    assert_not_nil comment.short_id
    assert_equal 6, comment.short_id.length
  end

  test "should delegate text and author to activity_object" do
    comment = Comment.new
    comment.build_activity_object(
      description: "Delegation works",
      author: @actor,
      user_author: @user,
      owner: @actor
    )
    comment.save!

    assert_equal "Delegation works", comment.text
    assert_equal @actor, comment.author
  end

  test "should compute wilson_confidence score correctly" do
    assert_equal 0, Comment.wilson_confidence(0, 0)
    
    score1 = Comment.wilson_confidence(10, 0)
    score2 = Comment.wilson_confidence(10, 5)
    
    assert score1 > score2
    assert score1 > 0
  end
end
