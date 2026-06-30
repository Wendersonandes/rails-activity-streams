require "test_helper"

class ContactTest < ActiveSupport::TestCase
  setup do
    seed_permissions_and_relations
    @alice = users(:alice)
    @bob = users(:bob)
    @sender = create_profile_for(@alice)
    @receiver = create_profile_for(@bob)
  end

  test "validates uniqueness of sender+receiver pair" do
    Contact.create!(sender: @sender, receiver: @receiver)
    duplicate = Contact.new(sender: @sender, receiver: @receiver)

    assert_not duplicate.valid?
  end

  test "#established? true when ties_count > 0" do
    contact = Contact.create!(sender: @sender, receiver: @receiver)
    assert_not contact.established?

    Tie.create!(contact: contact, relation: Relation::Public.instance)
    assert contact.reload.established?
  end

  test "auto-links inverse contact after create" do
    contact = Contact.create!(sender: @sender, receiver: @receiver)
    inverse = Contact.create!(sender: @receiver, receiver: @sender)

    assert_equal inverse.id, contact.reload.inverse_id
    assert_equal contact.id, inverse.reload.inverse_id
  end
end
