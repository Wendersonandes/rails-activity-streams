class ObjectLikedNotifier < ApplicationNotifier
  validate :activity_is_like

  private

  def activity_is_like
    if params[:activity] && !params[:activity].verb_like?
      errors.add(:base, "Activity must be a like")
    end
  end

  notification_methods do
    def message
      activity = params[:activity]
      if activity&.author
        "#{activity.author.name} curtiu sua publicação."
      else
        "Alguém curtiu sua publicação."
      end
    end

    def url
      activity = params[:activity]
      if activity
        parent_activity = activity.parent || activity
        Rails.application.routes.url_helpers.activity_path(parent_activity)
      else
        Rails.application.routes.url_helpers.root_path
      end
    end
  end
end
