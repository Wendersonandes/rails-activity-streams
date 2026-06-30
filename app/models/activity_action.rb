# == Schema Information
#
# Table name: activity_actions
#
#  id                 :bigint           not null, primary key
#  follow             :boolean          default(FALSE)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  activity_object_id :bigint           not null
#  actor_id           :bigint           not null
#
# Indexes
#
#  index_activity_actions_on_activity_object_id               (activity_object_id)
#  index_activity_actions_on_actor_id_and_activity_object_id  (actor_id,activity_object_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (activity_object_id => activity_objects.id) ON DELETE => restrict
#  fk_rails_...  (actor_id => actors.id) ON DELETE => restrict
#
class ActivityAction < ApplicationRecord
  belongs_to :actor
  belongs_to :activity_object

  scope :sent_by, ->(actor) { where(actor: actor) if actor.present? }
  scope :not_sent_by, ->(actor) {
    where.not(actor_id: Actor.normalize_id(actor)) if actor.present?
  }
  scope :received_by, ->(activity_object) {
    where(activity_object: ActivityObject.normalize(activity_object)) if activity_object.present?
  }
  scope :followed, -> { where(follow: true) }

  validates :actor, :activity_object, presence: true

  def follow!
    update!(follow: true)
  end

  def unfollow!
    update!(follow: false)
  end
end
