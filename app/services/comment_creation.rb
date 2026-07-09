# Service object to create a new comment activity on an existing target activity.
# It encapsulates building the concrete Comment object, its backing ActivityObject,
# establishing the parent-child Activity thread link, copying visibility audiences,
# recording the author's initial upvote, updating comment counters and score.
class CommentCreation
  # @param author [Actor] the profile actor authoring the comment
  # @param user_author [User] the logged-in user
  # @param parent_activity [Activity] the target activity being commented on
  # @param text [String] the text/body of the comment
  def initialize(author:, user_author:, parent_activity:, text:)
    @author = author
    @user_author = user_author
    @parent_activity = parent_activity
    @text = text
  end

  # Creates the comment in a database transaction.
  #
  # @return [Activity] the persisted comment Activity
  def call
    Activity.transaction do
      # 1. Create the concrete Comment record
      comment = Comment.new

      # 2. Build the backing ActivityObject (delegates text/description)
      comment.build_activity_object(
        description: @text,
        author: @author,
        user_author: @user_author,
        owner: @parent_activity.owner
      )
      comment.save!

      # 3. Compute depth (increments parent comment depth or starts at 0 for root comments)
      parent_comment_ao = @parent_activity.direct_object
      parent_comment = parent_comment_ao&.objectable if parent_comment_ao&.objectable_type == "Comment"
      depth = parent_comment ? parent_comment.depth + 1 : 0
      comment.update!(depth: depth)

      # 4. Create the comment Activity (verb: :post, parent points to target)
      comment_activity = Activity.new(
        verb: :post,
        author: @author,
        user_author: @user_author,
        owner: @parent_activity.owner,
        parent: @parent_activity
      )
      comment_activity.save!
      
      comment_activity.activity_object_activities.create!(
        activity_object: comment.activity_object,
        object_type: "Comment"
      )

      # 5. Propagates visibility by copying audiences from the parent activity
      @parent_activity.audiences.each do |audience|
        comment_activity.audiences.create!(relation_id: audience.relation_id)
      end

      # 6. Record author's upvote (automatic like)
      like_activity = Activity.create!(
        verb: :like,
        author: @author,
        user_author: @user_author,
        owner: comment.activity_object.owner || @author,
        parent: comment_activity
      )
      # Copy comment activity audiences to the like
      comment_activity.audiences.each do |audience|
        like_activity.audiences.create!(relation_id: audience.relation_id)
      end

      # 7. Update score/confidence of the comment object
      comment.update_score!(comment_activity)

      # 8. Increment parent's comment_count
      @parent_activity.direct_object&.increment!(:comment_count)

      comment_activity
    end
  end
end
