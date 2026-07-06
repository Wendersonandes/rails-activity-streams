# == Schema Information
#
# Table name: ties
#
#  id          :bigint           not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  contact_id  :bigint           not null
#  relation_id :bigint           not null
#
# Indexes
#
#  index_ties_on_contact_id_and_relation_id  (contact_id,relation_id) UNIQUE
#  index_ties_on_relation_id                 (relation_id)
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id) ON DELETE => restrict
#  fk_rails_...  (relation_id => relations.id) ON DELETE => restrict
#

# A {Tie} is the materialized link between two {Actor Actors}. It joins a {Contact}
# (which defines the +sender+ that declares the link and the +receiver+ it points to)
# with a {Relation} (which defines the *type* of the link: friend, follower, etc.).
#
# == Authorization
# Establishing a {Tie} is how an actor grants {Permission Permissions} to another: the
# permissions come from the {#relation} of the tie. A {Contact} only becomes active once it
# has at least one {Tie}.
#
# == Side effects
# The first {Tie} of a {Contact} triggers a contact {Activity} (a +follow+, or +make_friend+
# when the contact was already replied) — see {#create_contact_activity}.
#
# @see Contact  The ordered pair of actors backing this tie.
# @see Relation The type of link and the permissions it grants.
class Tie < ApplicationRecord
  belongs_to :contact, counter_cache: true, inverse_of: :ties
  belongs_to :relation

  has_one :sender, through: :contact
  has_one :receiver, through: :contact
  has_many :permissions, through: :relation

  # Ties whose sender (via {Contact}) is +a+.
  #
  # @param a [Actor, Integer] the sender (or its id).
  # @return [ActiveRecord::Relation<Tie>]
  scope :sent_by, ->(a) { joins(:contact).merge(Contact.sent_by(a)) }

  # Ties whose receiver (via {Contact}) is +a+.
  #
  # @param a [Actor, Integer] the receiver (or its id).
  # @return [ActiveRecord::Relation<Tie>]
  scope :received_by, ->(a) { joins(:contact).merge(Contact.received_by(a)) }

  # Ties of the given {Relation Relation(s)}. Returns all ties when +r+ is blank.
  #
  # @param r [Relation, Integer, String, Array, nil] the relation(s) or their id(s).
  # @return [ActiveRecord::Relation<Tie>]
  scope :related_by, ->(r) { where(relation_id: Relation.normalize_id(r)) if r.present? }

  # Ties whose {Relation} is positive (a real, active connection).
  #
  # @return [ActiveRecord::Relation<Tie>]
  scope :positive, -> { joins(:relation).merge(Relation.positive) }

  # Ties whose {Relation} grants permission to perform +action+ on +object+ (authorization).
  #
  # @param action [Symbol, String] the permission action. Valid values are the keys of {Permission.actions} (e.g. :create, :read).
  # @param object [Symbol, String] the permission object. Valid values are the keys of {Permission.objects} (e.g. :activity, :tie).
  # @return [ActiveRecord::Relation<Tie>]
  # @see Relation.allowing
  scope :allowing, ->(action, object) {
    joins(:relation).merge(Relation.allowing(action, object))
  }

  validates :contact, :relation, presence: true
  validate :relation_must_belong_to_sender

  after_create :create_contact_activity

  # Is this tie's {#relation} a positive one?
  #
  # @return [Boolean]
  def positive?
    relation.positive?
  end

  private

  # +after_create+ callback: publishes the contact {Activity} for the first tie of a contact.
  #
  # Skipped when the relation type opts out via +Relation.create_activity?+ (e.g.
  # {Relation::Reject}) or when this is not the contact's first tie. The verb is +make_friend+
  # when the contact is already replied, otherwise +follow+.
  def create_contact_activity
    return unless relation.class.create_activity?

    sender_actor = contact.sender
    receiver_actor = contact.receiver

    return if contact.reload.ties_count != 1

    Activity.create!(
      verb: contact.replied? ? :make_friend : :follow,
      author: sender_actor,
      user_author: sender_actor.subject.is_a?(Profile) ? sender_actor.subject.user : nil,
      owner: receiver_actor,
      audiences: receiver_actor.activity_relation_ids.map { |rid| Audience.new(relation_id: rid) }
    )
  end

  # +validate+ callback: a relation must belong to the contact's sender (unless it is a
  # {Relation::Single}, which is system-wide and has no owner).
  def relation_must_belong_to_sender
    return if relation.is_a?(Relation::Single)
    return if contact&.sender_id == relation&.actor_id

    errors.add(:relation, "must belong to sender")
  end
end
