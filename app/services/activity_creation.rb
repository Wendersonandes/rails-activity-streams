class ActivityCreation
  def initialize(activity, text: nil, relation_ids: nil)
    @activity = activity
    @text = text
    @relation_ids = relation_ids
  end

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

      if @relation_ids.present?
        @relation_ids.each { |rid| @activity.audiences.create!(relation_id: rid) }
      else
        @activity.audiences.create!(relation: Relation::Public.instance)
      end

      @activity
    end
  end
end
