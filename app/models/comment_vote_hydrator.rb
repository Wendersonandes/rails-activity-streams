# Hydrates a list of comment activities with the voting/flagging state of a specific viewer actor.
# This prevents N+1 queries when rendering a list of comments by loading all interactions
# in a single database query.
class CommentVoteHydrator
  include Enumerable

  delegate :each, :size, :empty?, :any?, to: :@activities

  # @param activities [Array<Activity>] the comment activities to hydrate
  # @param actor [Actor, nil] the current viewing profile actor
  def initialize(activities, actor)
    @activities = activities
    @actor = actor
    hydrate!
  end

  private

  def hydrate!
    return if @actor.nil? || @activities.empty?

    activity_ids = @activities.map(&:id)
    
    # Fetch all upvotes, downvotes, and flags by the actor targeting these activities
    interactions = Activity.where(parent_id: activity_ids, author_id: @actor.id)
                           .where(verb: [:like, :dislike, :flag])
                           .to_a

    likes = interactions.select(&:verb_like?).index_by(&:parent_id)
    dislikes = interactions.select(&:verb_dislike?).index_by(&:parent_id)
    flags = interactions.select(&:verb_flag?).index_by(&:parent_id)

    @activities.each do |activity|
      activity.current_user_vote = if likes.key?(activity.id)
                                     1
                                   elsif dislikes.key?(activity.id)
                                     -1
                                   else
                                     0
                                   end
      activity.current_user_flagged = flags.key?(activity.id)
    end
  end
end
