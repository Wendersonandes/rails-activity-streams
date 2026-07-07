# Background job to destroy an {Activity} and clean up its associated dependencies
# (like posts, audiences, likes, comments).
# Deferring destruction to a background queue keeps the HTTP delete response
# thin and fast.
class DestroyActivityJob < ApplicationJob
  queue_as :default

  # Performs the asynchronous destruction of the activity.
  #
  # @param activity_id [Integer] the ID of the Activity to destroy.
  def perform(activity_id)
    activity = Activity.find_by(id: activity_id)
    return unless activity

    activity.destroy
  end
end
