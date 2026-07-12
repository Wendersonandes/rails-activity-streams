require "test_helper"

class MentionsHelperTest < ActionView::TestCase
  setup do
    seed_permissions_and_relations
    @user_alice = users(:alice)
    @alice = create_profile_for(@user_alice, name: "Alice")
    
    @user_bob = users(:bob)
    @bob = create_profile_for(@user_bob, name: "Bob")
    
    @post = Post.new
    @post.build_activity_object(
      description: "Hey @[Bob](bob)!",
      author: @alice,
      user_author: @user_alice,
      owner: @alice
    )
    @post.save!
  end

  test "should return raw text if no mentions exist in the database" do
    assert_equal "Hey @[Bob](bob)!", render_with_mentions(@post.activity_object)
  end

  test "should convert mentions to links when mention matches preloaded database records" do
    # Create the mention in the database
    @post.activity_object.mentions.create!(actor: @bob)
    
    # Reload association or load it explicitly
    ao = ActivityObject.includes(mentions: :actor).find(@post.activity_object.id)
    
    expected_link = "<a class=\"text-blue-600 hover:text-blue-700 hover:underline font-semibold\" data-turbo=\"false\" href=\"/profiles/#{@bob.slug}\">Bob</a>"
    assert_equal "Hey #{expected_link}!", render_with_mentions(ao)
  end

  test "should escape HTML in the description to prevent XSS" do
    @post.activity_object.update!(description: "<script>alert('xss')</script> @[Bob](bob)")
    @post.activity_object.mentions.create!(actor: @bob)

    ao = ActivityObject.includes(mentions: :actor).find(@post.activity_object.id)
    result = render_with_mentions(ao)

    assert_no_match /<script>/, result
    assert_match /&lt;script&gt;/, result
    assert_match /href="\/profiles\/#{@bob.slug}"/, result
  end

  test "render_editor_mentions should return raw description if no mentions exist" do
    assert_equal "Hey @[Bob](bob)!", render_editor_mentions(@post.activity_object)
  end

  test "render_editor_mentions should convert mentions to span pills when they exist in DB" do
    @post.activity_object.mentions.create!(actor: @bob)
    ao = ActivityObject.includes(mentions: :actor).find(@post.activity_object.id)

    expected_span = "<span class=\"mention-pill bg-blue-50 text-blue-700 px-1.5 py-0.5 rounded-md font-medium text-xs inline-block mx-0.5\" data-slug=\"bob\" contenteditable=\"false\">@Bob</span>"
    assert_equal "Hey #{expected_span}!", render_editor_mentions(ao)
  end

  test "render_editor_mentions should escape HTML to prevent XSS" do
    @post.activity_object.update!(description: "<img src=x onerror=alert(1)> @[Bob](bob)")
    @post.activity_object.mentions.create!(actor: @bob)
    ao = ActivityObject.includes(mentions: :actor).find(@post.activity_object.id)

    result = render_editor_mentions(ao)
    assert_no_match /<img/, result
    assert_match /&lt;img/, result
    assert_match /data-slug="bob"/, result
  end
end
