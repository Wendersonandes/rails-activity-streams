class ObjectCommentedNotifier < ApplicationNotifier
  validate :activity_is_comment

  private

  def activity_is_comment
    if params[:activity] && !(params[:activity].verb_post? && params[:activity].parent.present? && params[:activity].direct_object&.objectable_type == "Comment")
      errors.add(:base, "Activity must be a comment")
    end
  end

  notification_methods do
    def message
      activity = params[:activity]
      if activity&.author
        I18n.t("notifications.object_commented.message", author: activity.author.name)
      else
        I18n.t("notifications.object_commented.default_message")
      end
    end

    def url
      activity = params[:activity]
      if activity
        comment = activity.direct_object&.objectable
        if comment
          Rails.application.routes.url_helpers.comment_permalink_path(comment.short_id)
        else
          parent_activity = activity.parent || activity
          Rails.application.routes.url_helpers.activity_path(parent_activity)
        end
      else
        Rails.application.routes.url_helpers.root_path
      end
    end
  end
end
