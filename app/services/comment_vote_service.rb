# Service object to handle casting votes (upvote/downvote) on comment activities.
# An upvote is represented as a child Activity of verb :like, while a downvote is
# represented as a child Activity of verb :dislike.
# Handles toggle logic (canceling same vote, switching opposing votes) and updates scores.
class CommentVoteService
  # @param actor [Actor] the profile actor casting the vote
  # @param user [User] the logged-in user
  # @param comment_activity [Activity] the comment activity being voted on
  # @param value [Integer] 1 for upvote, -1 for downvote
  def initialize(actor:, user:, comment_activity:, value:)
    @actor = actor
    @user = user
    @comment_activity = comment_activity
    @value = value
  end

  # Performs the vote toggle and updates scores.
  def call
    target_verb = (@value == 1) ? :like : :dislike
    other_verb = (@value == 1) ? :dislike : :like

    Activity.transaction do
      # 1. Find if user already voted with the target action
      existing_target = Activity.find_by(
        parent_id: @comment_activity.id,
        author_id: @actor.id,
        verb: target_verb
      )

      # 2. Find if user voted with the opposing action
      existing_other = Activity.find_by(
        parent_id: @comment_activity.id,
        author_id: @actor.id,
        verb: other_verb
      )

      if existing_target
        # Toggle off: clicking the same vote removes it
        existing_target.destroy!
      else
        # Switch vote: remove opposing vote if it exists
        existing_other.destroy! if existing_other

        # Create new vote activity
        vote_activity = Activity.new(
          verb: target_verb,
          author: @actor,
          user_author: @user,
          owner: @comment_activity.author,
          parent: @comment_activity
        )
        vote_activity.save!
        
        # Copy audiences from the comment activity to maintain correct visibility permissions (asynchronously)
        CreateActivityAudiencesJob.perform_later(vote_activity.id, @comment_activity.relation_ids)
      end

      # 3. Recalculate score and confidence on the Comment record (synchronously for immediate UI update)
      comment = @comment_activity.direct_object.objectable
      comment.update_score!(@comment_activity)
    end
  end
end
