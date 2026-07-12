require "test_helper"

class MentionTest < ActiveSupport::TestCase
  setup do
    seed_permissions_and_relations
    @user1 = users(:alice)
    @actor1 = create_profile_for(@user1, name: "Alice")
    
    @user2 = users(:bob)
    @actor2 = create_profile_for(@user2, name: "Bob")

    @post = Post.new
    @post.build_activity_object(
      description: "Hello @[Bob](bob)",
      author: @actor1,
      user_author: @user1,
      owner: @actor1
    )
    @post.save!
  end

  test "should be valid with source activity_object and target actor" do
    mention = Mention.new(activity_object: @post.activity_object, actor: @actor2)
    assert mention.valid?
  end

  test "should require activity_object" do
    mention = Mention.new(actor: @actor2)
    assert_not mention.valid?
    assert_includes mention.errors[:activity_object], "must exist"
  end

  test "should require actor" do
    mention = Mention.new(activity_object: @post.activity_object)
    assert_not mention.valid?
    assert_includes mention.errors[:actor], "must exist"
  end

  test "should enforce unique mention per activity_object" do
    Mention.create!(activity_object: @post.activity_object, actor: @actor2)
    
    duplicate = Mention.new(activity_object: @post.activity_object, actor: @actor2)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:actor_id], "can only be mentioned once per post or comment"
  end
end
