# Represents a mention of an {Actor} within an {ActivityObject}'s text (e.g. Post or Comment).
# It provides a durable database record linking the source content to the target recipient.
#
# == Schema Information
#
# Table name: mentions
#
#  id                 :bigint           not null, primary key
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  activity_object_id :bigint           not null
#  actor_id           :bigint           not null
#
# Indexes
#
#  index_mentions_on_activity_object_id               (activity_object_id)
#  index_mentions_on_activity_object_id_and_actor_id  (activity_object_id,actor_id) UNIQUE
#  index_mentions_on_actor_id                         (actor_id)
#
# Foreign Keys
#
#  fk_rails_...  (activity_object_id => activity_objects.id) ON DELETE => cascade
#  fk_rails_...  (actor_id => actors.id) ON DELETE => cascade
#
class Mention < ApplicationRecord
  # Associations
  belongs_to :activity_object
  belongs_to :actor

  # Validations
  validates :activity_object, presence: true
  validates :actor, presence: true
  validates :actor_id, uniqueness: { scope: :activity_object_id, message: "can only be mentioned once per post or comment" }
end
