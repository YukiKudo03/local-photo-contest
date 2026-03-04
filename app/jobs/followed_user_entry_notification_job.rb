# frozen_string_literal: true

class FollowedUserEntryNotificationJob < ApplicationJob
  queue_as :default

  def perform(entry_id)
    entry = Entry.find_by(id: entry_id)
    return unless entry

    entry.user.followers.find_each do |follower|
      Notification.create!(
        user: follower,
        notifiable: entry,
        notification_type: "followed_user_entry",
        title: I18n.t("services.broadcaster.followed_user_entry_title", user: entry.user.display_name),
        body: I18n.t("services.broadcaster.followed_user_entry_message", user: entry.user.display_name, contest: entry.contest.title)
      )

      NotificationBroadcaster.followed_user_new_entry(entry, follower)

      if follower.email_enabled?(:followed_entry)
        NotificationMailer.followed_user_entry(entry, follower).deliver_later
      end
    rescue => e
      Rails.logger.error("[FollowedUserEntryNotificationJob] Failed for follower #{follower.id}: #{e.message}")
    end
  end
end
