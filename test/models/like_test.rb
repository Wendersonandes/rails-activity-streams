require "test_helper"

class LikeTest < ActiveSupport::TestCase
  setup do
    seed_permissions_and_relations
    @alice = users(:alice)
    @bob = users(:bob)
    @author = create_profile_for(@alice)
    @owner = create_profile_for(@bob)

    # Create a post correctly
    @post = Post.new
    @post.build_activity_object(
      title: "",
      description: "Hello world",
      author: @author,
      user_author: @alice,
      owner: @owner
    )
    @post.save!
    @post_activity_object = @post.activity_object

    @post_activity = Activity.create!(
      verb: :post,
      author: @author,
      owner: @owner,
      user_author: @alice,
      activity_objects: [ @post_activity_object ],
      relation_ids: [ Relation::Public.instance.id ]
    )
  end

  test "builds a new like for an activity" do
    like = Like.build(@owner, @bob, @post_activity)
    
    assert like.new_record?
    assert_equal @post_activity, like.object
    assert_equal :like, like.verb.to_sym
    assert_equal @owner, like.author
    assert_equal @bob, like.user_author
    assert_equal @post_activity, like.parent
  end

  test "builds and saves a like for an activity object" do
    like = Like.build(@owner, @bob, @post)
    
    assert like.new_record?
    assert_equal @post, like.object
    assert like.save
    assert_not like.new_record?

    # Now find it
    found = Like.find(@owner, @post)
    assert_not_nil found
    assert_equal like.id, found.id
    assert_equal @post, found.object
  end

  test "find! raises ActiveRecord::RecordNotFound when not found" do
    assert_raises(ActiveRecord::RecordNotFound) do
      Like.find!(@owner, @post)
    end
  end

  test "returns existing like when calling build on already liked object" do
    like1 = Like.build(@owner, @bob, @post)
    assert like1.save

    like2 = Like.build(@owner, @bob, @post)
    assert_equal like1.id, like2.id
  end

  test "destroy deletes the underlying activity" do
    like = Like.build(@owner, @bob, @post)
    assert like.save

    assert_difference -> { Activity.count }, -1 do
      like.destroy
    end
  end
end
