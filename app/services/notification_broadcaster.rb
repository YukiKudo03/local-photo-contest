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
        title: "新規応募",
        message: "「#{entry.contest.title}」に新しい作品が投稿されました：#{entry.title.presence || '無題'}",
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
      status_text = case entry.moderation_status
      when "moderation_approved" then "承認されました"
      when "moderation_hidden" then "却下されました"
      else "審査待ちです"
      end

      notify_user(
        entry.user,
        title: "作品審査結果",
        message: "「#{entry.contest.title}」への応募作品「#{entry.title.presence || '無題'}」が#{status_text}",
        type: entry.moderation_approved? ? "success" : "warning",
        link: Rails.application.routes.url_helpers.entry_path(entry)
      )
    end

    # Broadcast contest status change to participants
    def contest_status_change(contest, new_status)
      status_messages = {
        "accepting_entries" => "の応募が開始されました",
        "finished" => "の応募が終了しました",
        "results_announced" => "の結果が発表されました"
      }

      message_suffix = status_messages[new_status.to_s] || "のステータスが変更されました"

      # Notify all participants
      contest.entries.includes(:user).find_each do |entry|
        notify_user(
          entry.user,
          title: "コンテスト更新",
          message: "「#{contest.title}」#{message_suffix}",
          type: "info",
          link: Rails.application.routes.url_helpers.contest_path(contest)
        )
      end

      # Notify all judges
      contest.contest_judges.includes(:user).find_each do |judge|
        notify_user(
          judge.user,
          title: "コンテスト更新",
          message: "「#{contest.title}」#{message_suffix}",
          type: "info",
          link: Rails.application.routes.url_helpers.my_judge_assignment_path(judge)
        )
      end
    end

    # Broadcast to contest channel (for real-time updates on contest pages)
    def contest_update(contest, data)
      ContestChannel.broadcast_to(contest, data)
    end
  end
end
