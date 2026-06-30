require "test_helper"

# == Schema Information
#
# Table name: actors
#
#  id                    :bigint           not null, primary key
#  actorable_type        :string           not null
#  description           :text
#  email                 :string
#  name                  :string           not null
#  notification_settings :jsonb
#  slug                  :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  activity_object_id    :bigint
#  actorable_id          :bigint           not null
#
# Indexes
#
#  index_actors_on_activity_object_id               (activity_object_id)
#  index_actors_on_actorable_type_and_actorable_id  (actorable_type,actorable_id) UNIQUE
#  index_actors_on_slug                             (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (activity_object_id => activity_objects.id) ON DELETE => nullify
#
class ActorTest < ActiveSupport::TestCase
  setup do
    seed_permissions_and_relations
    @alice = users(:alice)
    @bob = users(:bob)
    @alice_actor = create_profile_for(@alice, name: "Alice")
    @bob_actor = create_profile_for(@bob, name: "Bob")
  end

  test "validates presence of name" do
    actor = Actor.new(actorable_type: "Profile", actorable_id: 1)
    assert_not actor.valid?
    assert_includes actor.errors[:name], "can't be blank"
  end

  test "generates slug from name via FriendlyId" do
    assert_equal "alice", @alice_actor.slug
  end

  test "delegates to profile via delegated_type" do
    assert @alice_actor.profile?
    assert_not @alice_actor.group?
    assert_instance_of Profile, @alice_actor.profile
  end

  test "creates initial relations after create" do
    assert @alice_actor.relations.where(type: "Relation::Custom").exists?
  end

  test "#connect_to creates contact and tie" do
    assert_difference [ "Contact.count", "Tie.count" ], 1 do
      @alice_actor.connect_to(@bob_actor, as: "friend")
    end
  end

  test "#contacts_for returns actors with given relation" do
    @alice_actor.connect_to(@bob_actor, as: "friend")
    contacts = @alice_actor.contacts_for("friend")

    assert_includes contacts, @bob_actor
  end

  test "#connected_with? returns true for established contacts" do
    @alice_actor.connect_to(@bob_actor, as: "friend")
    assert @alice_actor.connected_with?(@bob_actor)
    assert_not @alice_actor.connected_with?(@alice_actor)
  end

  test "#allow? checks permissions via ties" do
    @alice_actor.connect_to(@bob_actor, as: "friend")
    assert @alice_actor.allow?(@bob_actor, :read, :activity)
  end

  test "#pending_contacts shows received contacts without reply" do
    @bob_actor.connect_to(@alice_actor, as: "friend")
    pending = @alice_actor.pending_contacts

    assert_equal 1, pending.count
  end

  test "#normalize returns Actor from various inputs" do
    assert_equal @alice_actor, Actor.normalize(@alice_actor)
    assert_equal @alice_actor, Actor.normalize(@alice_actor.id)
    assert_raises { Actor.normalize("not_found") }
  end

  test "#normalize handles nil gracefully" do
    assert_raises { Actor.normalize(nil) }
  end
end
