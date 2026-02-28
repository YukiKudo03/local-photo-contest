# frozen_string_literal: true

class ContestJudge < ApplicationRecord
  # Associations
  belongs_to :contest
  belongs_to :user
  has_many :judge_evaluations, dependent: :destroy
  has_many :judge_comments, dependent: :destroy

  # Validations
  validates :user_id, uniqueness: { scope: :contest_id, message: :already_a_judge }

  # Scopes
  scope :for_contest, ->(contest) { where(contest: contest) }
  scope :for_user, ->(user) { where(user: user) }

  # Instance Methods
  def evaluated_entry?(entry)
    judge_evaluations.exists?(entry: entry)
  end

  def fully_evaluated_entry?(entry)
    criteria_count = contest.evaluation_criteria.count
    return false if criteria_count.zero?

    judge_evaluations.where(entry: entry).count == criteria_count
  end

  def evaluation_progress
    entries_count = contest.entries.count
    return 0 if entries_count.zero?

    fully_evaluated_count = contest.entries.count { |entry| fully_evaluated_entry?(entry) }
    (fully_evaluated_count.to_f / entries_count * 100).round
  end

  # Reminder tracking
  REMINDER_SCHEDULE = [3, 1, 0].freeze

  def effective_deadline
    contest.judging_deadline_at || contest.entry_end_at
  end

  def needs_reminder?
    return false if evaluation_progress >= 100
    return false unless effective_deadline

    days_remaining = (effective_deadline.to_date - Date.current).to_i
    return false if days_remaining < 0
    return false unless REMINDER_SCHEDULE.include?(days_remaining)

    expected_count = REMINDER_SCHEDULE.index(days_remaining) + 1
    reminder_count < expected_count
  end

  def reminder_urgency
    return nil unless needs_reminder?

    days_remaining = (effective_deadline.to_date - Date.current).to_i
    case days_remaining
    when 3 then :warning
    when 1 then :urgent
    when 0 then :final
    end
  end

  def record_reminder_sent!
    update!(last_reminder_sent_at: Time.current, reminder_count: reminder_count + 1)
  end
end
