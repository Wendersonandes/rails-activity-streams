class PostPublishedNotifier < ApplicationNotifier
  notification_methods do
    def message
      "#{params[:activity].author.name} publicou um novo post."
    end

    def url
      Rails.application.routes.url_helpers.activity_path(params[:activity])
    end
  end
end
