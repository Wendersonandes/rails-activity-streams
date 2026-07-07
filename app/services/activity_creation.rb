# Service object that persists an {Activity} together with its content and audience in a
# single transaction.
#
# When +text+ is given it builds a {Post} (wrapped in an {ActivityObject}) and attaches it to
# the activity. The activity is then shared with the given +relation_ids+, defaulting to the
# {Relation::Public public relation} when none are provided.
#
# @see Activity
# @see Post
class ActivityCreation
  # @param activity [Activity] an unsaved activity carrying its author, owner and user_author.
  # @param text [Hash, nil] optional post content, with +:title+ and +:body+ keys.
  # @param relation_ids [Array<Integer>, nil] relations defining the audience; defaults to public.
  def initialize(activity, text: nil, relation_ids: nil)
    @activity = activity
    @text = text
    @relation_ids = relation_ids
  end

  # Builds the optional post, saves the activity and creates its audiences.
  #
  # @return [Activity] the persisted activity.
  # @raise [ActiveRecord::RecordInvalid] if any record fails validation (rolls back the transaction).
  def call
    Activity.transaction do
      if @text.present?
        post = Post.new
        post.build_activity_object(
          title: @text[:title].presence || "",
          description: @text[:body],
          author: @activity.author,
          user_author: @activity.user_author,
          owner: @activity.owner
        )
        post.save!
        @activity.activity_objects << post.activity_object
      end

      @activity.save!

      CreateActivityAudiencesJob.perform_later(@activity.id, @relation_ids)

      @activity
    end
  end
end
