# frozen_string_literal: true

class JudgeComment < ApplicationRecord
  # Associations
  belongs_to :contest_judge
  belongs_to :entry

  # Validations
  validates :comment, presence: true, length: { maximum: 2000 }
  validates :entry_id, uniqueness: {
    scope: :contest_judge_id,
    message: :already_commented
  }
  validate :cannot_comment_own_entry
  validate :comment_editable

  # Delegation
  delegate :contest, to: :contest_judge
  delegate :user, to: :contest_judge

  private

  def cannot_comment_own_entry
    return unless contest_judge && entry

    if entry.user_id == contest_judge.user_id
      errors.add(:base, :cannot_comment_own_entry)
    end
  end

  def comment_editable
    return unless contest_judge&.contest

    if contest_judge.contest.results_announced?
      errors.add(:base, :cannot_edit_after_results)
    end
  end
end
