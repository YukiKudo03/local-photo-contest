# frozen_string_literal: true

class FollowNotificationJob < ApplicationJob
  queue_as :default

  def perform(follow_id)
    follow = Follow.find_by(id: follow_id)
    return unless follow

    # Create in-app notification
    Notification.create!(
      user: follow.followed,
      notifiable: follow,
      notification_type: "new_follower",
      title: I18n.t("services.broadcaster.new_follower_title", user: follow.follower.display_name),
      body: I18n.t("services.broadcaster.new_follower_message")
    )

    # Broadcast real-time
    NotificationBroadcaster.new_follower(follow)

    # Send email if enabled
    if follow.followed.email_enabled?(:new_follower)
      NotificationMailer.new_follower(follow).deliver_later
    end
  rescue => e
    Rails.logger.error("[FollowNotificationJob] Failed: #{e.message}")
  end
end
