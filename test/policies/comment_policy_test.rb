require "test_helper"

class CommentPolicyTest < ActiveSupport::TestCase
  setup do
    seed_permissions_and_relations
    @alice = users(:alice)
    @bob   = users(:bob)
    @alice_actor = create_profile_for(@alice, name: "Alice")
    @bob_actor   = create_profile_for(@bob, name: "Bob")

    @comment = Comment.new
    @comment.build_activity_object(
      description: "Policy comment",
      author: @alice_actor,
      owner: @alice_actor
    )
  end

  test "logged in user can create and reply to comment" do
    policy = CommentPolicy.new(@bob, @comment)
    assert policy.create?
    assert policy.reply?
    assert policy.upvote?
    assert policy.downvote?
    assert policy.flag?
  end

  test "only author can update comment" do
    policy_alice = CommentPolicy.new(@alice, @comment)
    policy_bob   = CommentPolicy.new(@bob, @comment)
    
    assert policy_alice.update?
    assert_not policy_bob.update?
  end

  test "author or owner can destroy comment" do
    policy_alice = CommentPolicy.new(@alice, @comment)
    policy_bob   = CommentPolicy.new(@bob, @comment)
    
    assert policy_alice.destroy?
    assert_not policy_bob.destroy?
  end

  test "signed out user cannot create comment" do
    policy = CommentPolicy.new(nil, @comment)
    assert_not policy.create?
    assert_not policy.reply?
  end
end
