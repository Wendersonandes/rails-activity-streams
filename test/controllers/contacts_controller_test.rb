require "test_helper"

class ContactsControllerTest < ActionDispatch::IntegrationTest
  setup do
    seed_permissions_and_relations
    @user = users(:alice)
    @alice = create_profile_for(@user)
    @user.update!(current_profile: @alice)

    @bob = create_profile_for(users(:bob))
    sign_in @user
  end

  test "should get index" do
    get contacts_path
    assert_response :success
  end

  test "should create contact" do
    assert_difference("Contact.count", 1) do
      post contacts_path, params: { actor_id: @bob.slug, as: :friend }
    end
    assert_redirected_to contacts_path
  end

  test "should destroy contact" do
    @alice.connect_to(@bob, as: :friend)
    contact = Contact.last

    assert_difference("Contact.count", -1) do
      delete contact_path(contact)
    end
    assert_redirected_to contacts_path
  end

  test "group admin tie does not appear as pending contact" do
    group = Group.new
    group.build_actor(name: "Test Group")
    GroupCreation.new(@alice, group).call

    get contacts_path
    assert_response :success
    assert_no_match /Test Group/, response.body
  end
end
