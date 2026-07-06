require "test_helper"

class SuggestionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    seed_permissions_and_relations
    @user = users(:alice)
    @alice = create_profile_for(@user)
    @user.update!(current_profile: @alice)
    sign_in @user
  end

  test "should get index" do
    get suggestions_path
    assert_response :success
    assert_match /turbo-frame id="sidebar_suggestions"/, response.body
  end
end
