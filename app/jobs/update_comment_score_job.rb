# Background job to recalculate the score and Wilson confidence of a comment.
# Deferring this to a background queue helps reduce database write contention
# on the comments table under high voting traffic.
#
# @see CommentVoteService
# @see Comment
class UpdateCommentScoreJob < ApplicationJob
  queue_as :default

  # Performs the asynchronous score update.
  #
  # @param comment_activity_id [Integer] the ID of the comment's Activity.
  def perform(comment_activity_id)
    comment_activity = Activity.find_by(id: comment_activity_id)
    return unless comment_activity

    comment = comment_activity.direct_object&.objectable
    return unless comment && comment.is_a?(Comment)

    comment.update_score!(comment_activity)
  end
end
