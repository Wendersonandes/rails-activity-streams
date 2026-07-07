# Convenience class for managing like activities in Rails 8+
class Like
  include ActiveModel::Model

  # Delegate all ActiveRecord methods (save, destroy, persisted?, errors, etc.) 
  # directly to the wrapped Activity record.
  delegate_missing_to :@like

  attr_reader :like

  class << self
    # Find the child activity of verb: :like targeted to object, authored by subject
    #
    # @param subject [Actor]
    # @param object [Activity, ActivityObject, Post, Profile, Group]
    # @return [Like, nil]
    def find(subject, object)
      activity = case object
                 when Activity
                   if object.likes.loaded?
                     object.likes.detect { |l| l.author_id == Actor.normalize_id(subject) }
                   else
                     object.likes.find_by(author: subject)
                   end
                 else
                   ActivityObject.normalize(object).likes.find_by(author: subject)
                 end

      new(activity) if activity
    end

    # Like #find but raises ActiveRecord::RecordNotFound if not found
    #
    # @param subject [Actor]
    # @param object [Activity, ActivityObject, Post, Profile, Group]
    # @return [Like]
    # @raise [ActiveRecord::RecordNotFound]
    def find!(subject, object)
      find(subject, object) ||
        raise(ActiveRecord::RecordNotFound, "Like activity not found for subject and object")
    end

    # Builds a new Like activity wrapper
    #
    # @param subject [Actor]
    # @param user [User]
    # @param object [Activity, ActivityObject, Post, Profile, Group]
    # @return [Like]
    def build(subject, user, object)
      find(subject, object) || build_new_like(subject, user, object)
    end

    private

    def build_new_like(subject, user, object)
      activity = Activity.new(
        verb: :like,
        author: Actor.normalize(subject),
        user_author: user
      )

      if object.is_a?(Activity)
        activity.parent = object
        activity.owner = object.author
      else
        activity_object = ActivityObject.normalize(object)
        activity.activity_objects << activity_object
        activity.owner = activity_object.owner || activity.author
      end

      new(activity)
    end
  end

  def initialize(activity)
    @like = activity
  end

  # Returns the actual record that is liked (an Activity, Post, Profile, or Group)
  def object
    @object ||= begin
      return nil if @like.nil?

      if @like.root?
        @like.direct_object&.object
      else
        @like.parent
      end
    end
  end
end
