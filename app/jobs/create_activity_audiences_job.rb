# Background job to create {Audience} records for a newly published {Activity}.
# Deferring audience association to a background queue helps keep the HTTP
# post request fast.
#
# @see ActivityCreation
# @see Activity
# @see Audience
class CreateActivityAudiencesJob < ApplicationJob
  queue_as :default

  # Performs the asynchronous creation of audiences.
  #
  # @param activity_id [Integer] the ID of the Activity.
  # @param relation_ids [Array<Integer>, nil] the relation IDs defining the audience.
  def perform(activity_id, relation_ids)
    activity = Activity.find_by(id: activity_id)
    return unless activity

    # Prevent double creation
    return if activity.audiences.any?

    Activity.transaction do
      if relation_ids.present?
        relation_ids.each do |rid|
          activity.audiences.create!(relation_id: rid)
        end
      else
        activity.audiences.create!(relation: Relation::Public.instance)
      end
    end
  end
end
