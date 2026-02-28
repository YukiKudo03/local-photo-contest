# frozen_string_literal: true

class ContestArchiveService
  attr_reader :contest

  def initialize(contest)
    @contest = contest
  end

  def archive!
    contest.archive!

    AuditLog.log(
      action: "contest_auto_archive",
      user: contest.user,
      target: contest,
      details: { auto_archive_days: contest.auto_archive_days }
    )

    NotificationMailer.contest_archived(contest.user, contest).deliver_later
  end

  def unarchive!
    contest.unarchive!

    AuditLog.log(
      action: "contest_unarchive",
      user: contest.user,
      target: contest
    )
  end
end
