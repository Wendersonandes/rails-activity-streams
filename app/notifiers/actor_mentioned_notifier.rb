class ActorMentionedNotifier < ApplicationNotifier
  # Inherits validation of params[:activity] from ApplicationNotifier

  notification_methods do
    # Returns the localized notification message.
    # e.g., "Alice Silva mentioned you in a post" or "Alice Silva mentioned you in a comment"
    def message
      activity = params[:activity]
      return I18n.t("notifications.actor_mentioned.default_message") unless activity&.author

      author_name = activity.author.name
      is_comment = activity.direct_object&.objectable_type == "Comment"

      if is_comment
        I18n.t("notifications.actor_mentioned.comment_message", author: author_name)
      else
        I18n.t("notifications.actor_mentioned.post_message", author: author_name)
      end
    end

    # Returns the redirect URL for the notification click.
    def url
      activity = params[:activity]
      return Rails.application.routes.url_helpers.root_path unless activity

      # Check if the direct object is a Comment
      direct_obj = activity.direct_object
      if direct_obj&.objectable_type == "Comment"
        comment = direct_obj.objectable
        if comment
          Rails.application.routes.url_helpers.comment_permalink_path(comment.short_id)
        else
          # Fallback to parent activity if comment object is gone
          parent_activity = activity.parent || activity
          Rails.application.routes.url_helpers.activity_path(parent_activity)
        end
      else
        # For posts or other activity objects
        Rails.application.routes.url_helpers.activity_path(activity)
      end
    end
  end
end
