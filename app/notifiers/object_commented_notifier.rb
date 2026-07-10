class ObjectCommentedNotifier < ApplicationNotifier
  notification_methods do
    def message
      "#{params[:activity].author.name} comentou em sua publicação."
    end

    def url
      comment = params[:activity].direct_object.objectable
      Rails.application.routes.url_helpers.comment_permalink_path(comment.short_id)
    end
  end
end
