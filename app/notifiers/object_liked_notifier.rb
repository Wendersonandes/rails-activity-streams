class ObjectLikedNotifier < ApplicationNotifier
  notification_methods do
    def message
      "#{params[:activity].author.name} curtiu sua publicação."
    end

    def url
      activity = params[:activity].parent || params[:activity]
      Rails.application.routes.url_helpers.activity_path(activity)
    end
  end
end
