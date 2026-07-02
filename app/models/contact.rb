# == Schema Information
#
# Table name: contacts
#
#  id          :bigint           not null, primary key
#  ties_count  :integer          default(0)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  inverse_id  :bigint
#  receiver_id :bigint           not null
#  sender_id   :bigint           not null
#
# Indexes
#
#  index_contacts_on_inverse_id                 (inverse_id)
#  index_contacts_on_receiver_id                (receiver_id)
#  index_contacts_on_sender_id_and_receiver_id  (sender_id,receiver_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (inverse_id => contacts.id) ON DELETE => nullify
#  fk_rails_...  (receiver_id => actors.id) ON DELETE => restrict
#  fk_rails_...  (sender_id => actors.id) ON DELETE => restrict
#
class Contact < ApplicationRecord
  belongs_to :inverse, class_name: "Contact", optional: true
  belongs_to :sender, class_name: "Actor"
  belongs_to :receiver, class_name: "Actor"

  has_many :ties, class_name: "Tie", dependent: :destroy, inverse_of: :contact
  has_many :relations, through: :ties

  scope :sent_by, ->(a) { where(sender_id: Actor.normalize_id(a)) }
  scope :received_by, ->(a) { where(receiver_id: Actor.normalize_id(a)) }
  scope :active, -> { where(arel_table[:ties_count].gt(0)) }
  scope :positive, -> {
    select("DISTINCT contacts.*")
      .joins(:relations)
      .merge(Relation.where(type: Relation.positive_names))
  }
  scope :not_reflexive, -> { where(arel_table[:sender_id].not_eq(arel_table[:receiver_id])) }

  scope :pending, -> {
    active.positive.not_reflexive
         .joins("LEFT JOIN contacts AS inverse_contacts ON inverse_contacts.id = contacts.inverse_id")
         .where(arel_table[:inverse_id].eq(nil).or(Contact.arel_table.alias("inverse_contacts")[:ties_count].eq(0)))
  }

  validates :sender, :receiver, presence: true
  validates :sender_id, uniqueness: { scope: :receiver_id }

  after_create :link_inverse

  def established?
    ties_count.to_i > 0
  end

  def reflexive?
    sender_id == receiver_id
  end

  def replied?
    inverse_id.present? && inverse&.established?
  end

  def inverse!
    inverse || receiver.contact_to!(sender)
  end

  private

  def link_inverse
    existing = self.class.find_by(sender_id: receiver_id, receiver_id: sender_id)
    return unless existing

    update_column(:inverse_id, existing.id)
    existing.update_column(:inverse_id, id)
  end
end
