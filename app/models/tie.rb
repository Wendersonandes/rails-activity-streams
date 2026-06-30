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
class Tie < ApplicationRecord
  belongs_to :contact, counter_cache: true, inverse_of: :ties
  belongs_to :relation

  has_one :sender, through: :contact
  has_one :receiver, through: :contact
  has_many :permissions, through: :relation

  scope :sent_by, ->(a) { joins(:contact).merge(Contact.sent_by(a)) }
  scope :received_by, ->(a) { joins(:contact).merge(Contact.received_by(a)) }
  scope :related_by, ->(r) { where(relation_id: Relation.normalize_id(r)) if r.present? }
  scope :positive, -> { joins(:relation).merge(Relation.positive) }
  scope :allowing, ->(action, object) {
    joins(:relation).merge(Relation.allowing(action, object))
  }

  validates :contact, :relation, presence: true
  validate :relation_must_belong_to_sender

  after_create :create_contact_activity

  def positive?
    relation.positive?
  end

  private

  def create_contact_activity
    return unless relation.class.create_activity?
    return if contact.reload.ties_count != 1

    Activity.create!(
      verb: contact.replied? ? :make_friend : :follow,
      author: contact.sender,
      user_author: contact.sender.subject.is_a?(Profile) ? contact.sender.subject.user : nil,
      owner: contact.receiver,
      relation_ids: contact.receiver.activity_relation_ids
    )
  end

  def relation_must_belong_to_sender
    return if relation.is_a?(Relation::Single)
    return if contact&.sender_id == relation&.actor_id

    errors.add(:relation, "must belong to sender")
  end
end
