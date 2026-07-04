# == Schema Information
#
# Table name: activity_object_activities
#
#  id                 :bigint           not null, primary key
#  object_type        :string           default("object")
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  activity_id        :bigint           not null
#  activity_object_id :bigint           not null
#
# Indexes
#
#  index_activity_object_activities_on_activity_id         (activity_id)
#  index_activity_object_activities_on_activity_object_id  (activity_object_id)
#
# Foreign Keys
#
#  fk_rails_...  (activity_id => activities.id) ON DELETE => cascade
#  fk_rails_...  (activity_object_id => activity_objects.id) ON DELETE => cascade
#

# Join model connecting an {Activity} to an {ActivityObject}. An activity may reference
# several objects, and the +object_type+ column records the role each object plays within the
# activity (e.g. "object", "Comment"), which is how {Activity#comments} tells comments apart.
#
# @see Activity
# @see ActivityObject
class ActivityObjectActivity < ApplicationRecord
  belongs_to :activity
  belongs_to :activity_object

  before_create :set_default_object_type

  private

  # +before_create+ callback: defaults +object_type+ to "object" when not provided.
  def set_default_object_type
    self.object_type ||= "object"
  end
end
