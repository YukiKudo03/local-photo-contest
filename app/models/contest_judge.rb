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
end
