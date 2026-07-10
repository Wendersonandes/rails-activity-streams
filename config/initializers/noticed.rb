# Custom configurations and class reopenings for the Noticed gem.
Rails.application.config.to_prepare do
  # 1. Reopen Noticed::Event to broadcast on creation (bypasses Notification insert_all callback limitation)
  Noticed::Event.class_eval do
    after_create_commit :broadcast_notifications_badge_update

    private

    def broadcast_notifications_badge_update
      notifications.each do |notification|
        recipient = notification.recipient
        next unless recipient.is_a?(Actor)

        Turbo::StreamsChannel.broadcast_replace_to(
          recipient,
          :notifications,
          target: "nav_notification_badge",
          partial: "shared/nav_notification_badge",
          locals: { actor: recipient }
        )
      end
    end
  end

  # 2. Reopen Noticed::Notification to broadcast on update/destroy (for marking as read/unread)
  Noticed::Notification.class_eval do
    after_commit :broadcast_badge_update, on: [ :update, :destroy ]

    private

    def broadcast_badge_update
      return unless recipient.is_a?(Actor)

      Turbo::StreamsChannel.broadcast_replace_to(
        recipient,
        :notifications,
        target: "nav_notification_badge",
        partial: "shared/nav_notification_badge",
        locals: { actor: recipient }
      )
    end
  end
end
