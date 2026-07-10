class PostPublishedNotifier < ApplicationNotifier
  validate :activity_is_post

  private

  def activity_is_post
    if params[:activity] && !params[:activity].verb_post?
      errors.add(:base, "Activity must be a post")
    end
  end

  notification_methods do
    def message
      activity = params[:activity]
      if activity&.author
        I18n.t("notifications.post_published.message", author: activity.author.name)
      else
        I18n.t("notifications.post_published.default_message")
      end
    end

    def url
      activity = params[:activity]
      if activity
        Rails.application.routes.url_helpers.activity_path(activity)
      else
        Rails.application.routes.url_helpers.root_path
      end
    end
  end
end
