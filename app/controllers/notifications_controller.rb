class NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notification, only: [ :update ]

  # GET /notifications
  def index
    authorize Noticed::Notification, policy_class: Noticed::NotificationPolicy
    @notifications = policy_scope(Noticed::Notification).order(created_at: :desc)
    @pagy, @notifications = pagy(@notifications, limit: 15)
  end

  # PATCH /notifications/:id
  def update
    authorize @notification, policy_class: Noticed::NotificationPolicy
    @notification.mark_as_read

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace(@notification, partial: "notifications/notification", locals: { notification: @notification }),
          turbo_stream.replace("nav_notification_badge", partial: "shared/nav_notification_badge")
        ]
      end
      format.html { redirect_to notifications_path }
    end
  end

  # POST /notifications/mark_all_as_read
  def mark_all_as_read
    authorize Noticed::Notification, :mark_all_as_read?, policy_class: Noticed::NotificationPolicy
    policy_scope(Noticed::Notification).unread.mark_as_read

    respond_to do |format|
      format.turbo_stream do
        @notifications = policy_scope(Noticed::Notification).order(created_at: :desc)
        @pagy, @notifications = pagy(@notifications, limit: 15)
        render turbo_stream: [
          turbo_stream.replace("notifications_list_container", partial: "notifications/list", locals: { notifications: @notifications, pagy: @pagy }),
          turbo_stream.replace("nav_notification_badge", partial: "shared/nav_notification_badge")
        ]
      end
      format.html { redirect_to notifications_path, notice: "All notifications marked as read." }
    end
  end

  private

  def set_notification
    @notification = Noticed::Notification.find(params[:id])
  end
end
