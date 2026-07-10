require "test_helper"

# == Schema Information
#
# Table name: flags
#
#  id         :bigint           not null, primary key
#  note       :text
#  reason     :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
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
