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

# An {ActivityAction} records a standing relationship between an {Actor} and an
# {ActivityObject} — currently whether the actor *follows* the object. Unlike an {Activity}
# (a one-off event), an action is a durable per-actor/per-object flag.
#
# @see Actor
# @see ActivityObject
class ActivityAction < ApplicationRecord
  belongs_to :actor
  belongs_to :activity_object

  # Actions performed by +actor+. Returns all actions when +actor+ is blank.
  #
  # @param actor [Actor, nil] the acting actor.
  # @return [ActiveRecord::Relation<ActivityAction>]
  scope :sent_by, ->(actor) { where(actor: actor) if actor.present? }

  # Actions not performed by +actor+. Returns all actions when +actor+ is blank.
  #
  # @param actor [Actor, Integer, nil] the excluded actor (or its id).
  # @return [ActiveRecord::Relation<ActivityAction>]
  scope :not_sent_by, ->(actor) {
    where.not(actor_id: Actor.normalize_id(actor)) if actor.present?
  }

  # Actions targeting +activity_object+. Returns all actions when it is blank.
  #
  # @param activity_object [ActivityObject, Integer, nil] the target object (or its id).
  # @return [ActiveRecord::Relation<ActivityAction>]
  scope :received_by, ->(activity_object) {
    where(activity_object: ActivityObject.normalize(activity_object)) if activity_object.present?
  }

  # Actions that represent a follow (+follow: true+).
  #
  # @return [ActiveRecord::Relation<ActivityAction>]
  scope :followed, -> { where(follow: true) }

  validates :actor, :activity_object, presence: true

  # Marks this action as following its {#activity_object}.
  #
  # @return [Boolean]
  def follow!
    update!(follow: true)
  end

  # Clears the follow flag on this action.
  #
  # @return [Boolean]
  def unfollow!
    update!(follow: false)
  end
end
