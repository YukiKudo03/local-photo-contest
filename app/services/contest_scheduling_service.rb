# frozen_string_literal: true

class ContestSchedulingService
  def initialize(contest)
    @contest = contest
  end

  def publish!
    @contest.publish!
    NotificationBroadcaster.contest_status_change(@contest, :published)
    AuditLog.log(
      action: "contest_auto_publish",
      user: @contest.user,
      target: @contest,
      details: { scheduled_publish_at: @contest.scheduled_publish_at&.iso8601 }
    )
  end

  def finish!
    @contest.finish!
    NotificationBroadcaster.contest_status_change(@contest, :finished)
    AuditLog.log(
      action: "contest_auto_finish",
      user: @contest.user,
      target: @contest,
      details: { scheduled_finish_at: @contest.scheduled_finish_at&.iso8601 }
    )
  end
end
