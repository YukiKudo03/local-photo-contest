# frozen_string_literal: true

module ContestStateMachine
  extend ActiveSupport::Concern

  included do
    validate :judging_method_not_changed_after_publish
  end

  # State transitions
  def publish!
    raise "Cannot publish: not a draft" unless draft?
    raise "Cannot publish: title is required" if title.blank?
    update!(status: :published)
  end

  def finish!
    raise "Cannot finish: not published" unless published?
    update!(status: :finished)
  end

  def announce_results!
    raise "Cannot announce results: contest is not finished" unless finished?
    raise "Results already announced" if results_announced?
    update!(results_announced_at: Time.current)
    send_results_notifications
  end

  # State checks
  def accepting_entries?
    return false unless published?
    return true if entry_start_at.nil? && entry_end_at.nil?

    now = Time.current
    (entry_start_at.nil? || now >= entry_start_at) &&
      (entry_end_at.nil? || now <= entry_end_at)
  end

  def ranking_calculatable?
    return false if entries.empty?
    return true if judging_vote_only?

    # For judge_only or hybrid, need at least some evaluations
    judge_completion_rate > 0
  end

  # Check if saved rankings are outdated
  # Rankings are outdated if any judge evaluation was modified after rankings were calculated
  def rankings_outdated?
    return false if contest_rankings.empty?

    last_ranking_calculation = contest_rankings.maximum(:calculated_at)
    return false unless last_ranking_calculation

    # Check if any evaluation was created/updated after the last ranking calculation
    latest_evaluation = JudgeEvaluation.joins(:contest_judge)
                                       .where(contest_judges: { contest_id: id })
                                       .maximum(:updated_at)

    return false unless latest_evaluation

    latest_evaluation > last_ranking_calculation
  end

  private

  def judging_method_not_changed_after_publish
    return unless persisted?
    return if draft?
    return unless judging_method_changed?

    errors.add(:judging_method, :cannot_change_after_publish)
  end
end
