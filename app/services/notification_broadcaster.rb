# frozen_string_literal: true

class NotificationBroadcaster
  class << self
    # Broadcast a notification to a specific user
    def notify_user(user, title:, message:, type: "info", link: nil)
      NotificationsChannel.broadcast_to(
        user,
        title: title,
        message: message,
        type: type,
        link: link,
        timestamp: Time.current.iso8601
      )
    end

    # Broadcast new entry notification to contest organizer
    def new_entry(entry)
      organizer = entry.contest.user
      notify_user(
        organizer,
        title: I18n.t('services.broadcaster.new_entry_title'),
        message: I18n.t('services.broadcaster.new_entry_message', contest: entry.contest.title, entry: entry.title.presence || I18n.t('common.untitled')),
        type: "entry",
        link: Rails.application.routes.url_helpers.organizers_contest_entry_path(entry.contest, entry)
      )
    end

    # Broadcast vote count update to all viewers of an entry
    def vote_update(entry)
      EntryChannel.broadcast_to(
        entry,
        type: "vote_update",
        entry_id: entry.id,
        vote_count: entry.votes.count
      )
    end

    # Broadcast moderation result to entry owner
    def moderation_result(entry)
      status_text = I18n.t("services.broadcaster.moderation_statuses.#{entry.moderation_status}", default: entry.moderation_status)

      notify_user(
        entry.user,
        title: I18n.t('services.broadcaster.moderation_result_title'),
        message: I18n.t('services.broadcaster.moderation_result_message', contest: entry.contest.title, entry: entry.title.presence || I18n.t('common.untitled'), status: status_text),
        type: entry.moderation_approved? ? "success" : "warning",
        link: Rails.application.routes.url_helpers.entry_path(entry)
      )
    end

    # Broadcast contest status change to participants
    def contest_status_change(contest, new_status)
      message = I18n.t("services.broadcaster.contest_statuses.#{new_status}", default: I18n.t('services.broadcaster.contest_status_changed'))

      # Notify all participants
      contest.entries.includes(:user).find_each do |entry|
        notify_user(
          entry.user,
          title: I18n.t('services.broadcaster.contest_update_title'),
          message: I18n.t('services.broadcaster.contest_update_message', contest: contest.title, status: message),
          type: "info",
          link: Rails.application.routes.url_helpers.contest_path(contest)
        )
      end

      # Notify all judges
      contest.contest_judges.includes(:user).find_each do |judge|
        notify_user(
          judge.user,
          title: I18n.t('services.broadcaster.contest_update_title'),
          message: I18n.t('services.broadcaster.contest_update_message', contest: contest.title, status: message),
          type: "info",
          link: Rails.application.routes.url_helpers.my_judge_assignment_path(judge)
        )
      end
    end

    # Broadcast new follower notification
    def new_follower(follow)
      notify_user(
        follow.followed,
        title: I18n.t("services.broadcaster.new_follower_title", user: follow.follower.display_name),
        message: I18n.t("services.broadcaster.new_follower_message"),
        type: "info",
        link: Rails.application.routes.url_helpers.user_path(follow.follower)
      )
    end

    # Broadcast notification when followed user posts new entry
    def followed_user_new_entry(entry, follower)
      notify_user(
        follower,
        title: I18n.t("services.broadcaster.followed_user_entry_title", user: entry.user.display_name),
        message: I18n.t("services.broadcaster.followed_user_entry_message", user: entry.user.display_name, contest: entry.contest.title),
        type: "entry",
        link: Rails.application.routes.url_helpers.entry_path(entry)
      )
    end

    # Broadcast reaction count update to entry viewers
    def reaction_update(entry)
      EntryChannel.broadcast_to(
        entry,
        type: "reaction_update",
        entry_id: entry.id,
        reactions_count: entry.reactions_count
      )
    end

    # Broadcast to contest channel (for real-time updates on contest pages)
    def contest_update(contest, data)
      ContestChannel.broadcast_to(contest, data)
    end
  end
end
