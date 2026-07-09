require "test_helper"

class FlagTest < ActiveSupport::TestCase
  setup do
    seed_permissions_and_relations
    @user = users(:alice)
    @actor = create_profile_for(@user)
  end

  test "validates reason is present and in allowed list" do
    flag = Flag.new(reason: nil)
    assert_not flag.valid?

    flag.reason = "invalid_reason"
    assert_not flag.valid?

    %w[spam harassment offtopic inappropriate].each do |reason|
      flag.reason = reason
      assert flag.valid?
    end
  end
end
