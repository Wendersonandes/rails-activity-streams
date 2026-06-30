require "test_helper"

class ContactFlowTest < ActionDispatch::IntegrationTest
  setup do
    seed_permissions_and_relations
    @alice = users(:alice)
    @bob = users(:bob)
    @alice_actor = create_profile_for(@alice, name: "Alice")
    @bob_actor = create_profile_for(@bob, name: "Bob")
  end

  test "full contact flow: connect → verify tie → check permissions" do
    @alice_actor.connect_to(@bob_actor, as: "friend")

    assert @alice_actor.connected_with?(@bob_actor)
    assert_not @bob_actor.connected_with?(@alice_actor)

    friend_rel = @alice_actor.relation_custom("friend")
    tie = @alice_actor.sent_ties.find_by(relation: friend_rel)
    assert tie
    assert tie.positive?

    assert @alice_actor.allow?(@bob_actor, :read, :activity)
  end

  test "contacts_for filters by relation" do
    @alice_actor.connect_to(@bob_actor, as: "friend")

    contacts = @alice_actor.contacts_for("friend")
    assert_includes contacts, @bob_actor
    assert_equal 1, contacts.count
  end

  test "bidirectional tie establishes mutual permissions" do
    @alice_actor.connect_to(@bob_actor, as: "friend")
    @bob_actor.connect_to(@alice_actor, as: "friend")

    assert @alice_actor.allow?(@bob_actor, :read, :activity)
    assert @bob_actor.allow?(@alice_actor, :read, :activity)
  end
end
