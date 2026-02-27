# frozen_string_literal: true

class JudgeEvaluation < ApplicationRecord
  # Associations
  belongs_to :contest_judge
  belongs_to :entry
  belongs_to :evaluation_criterion, class_name: "EvaluationCriterion"

  # Validations
  validates :score, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :entry_id, uniqueness: {
    scope: [ :contest_judge_id, :evaluation_criterion_id ],
    message: :already_evaluated
  }
  validate :score_within_max
  validate :cannot_evaluate_own_entry
  validate :entry_belongs_to_contest
  validate :evaluation_editable

  # Delegation
  delegate :contest, to: :contest_judge

  # Scopes
  scope :for_entry, ->(entry) { where(entry: entry) }
  scope :for_criterion, ->(criterion) { where(evaluation_criterion: criterion) }

  private

  def score_within_max
    return unless score && evaluation_criterion

    if score > evaluation_criterion.max_score
      errors.add(:score, :score_out_of_range, max: evaluation_criterion.max_score)
    end
  end

  def cannot_evaluate_own_entry
    return unless contest_judge && entry

    if entry.user_id == contest_judge.user_id
      errors.add(:base, :cannot_evaluate_own_entry)
    end
  end

  def entry_belongs_to_contest
    return unless entry && contest_judge

    if entry.contest_id != contest_judge.contest_id
      errors.add(:entry, :not_in_contest)
    end
  end

  def evaluation_editable
    return unless contest_judge&.contest

    if contest_judge.contest.results_announced?
      errors.add(:base, :cannot_edit_after_results)
    end
  end
end
