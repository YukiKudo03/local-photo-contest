# frozen_string_literal: true

class ResultsAnnouncementService
  attr_reader :contest

  def initialize(contest)
    @contest = contest
  end

  def preview
    calculator = RankingCalculator.new(contest)
    {
      rankings: calculator.preview,
      judge_completion_rate: contest.judge_completion_rate,
      can_announce: can_announce?,
      warnings: warnings,
      rankings_outdated: contest.rankings_outdated?
    }
  end

  def calculate_and_save
    calculator = RankingCalculator.new(contest)
    calculator.calculate
  end

  def announce!
    raise I18n.t('services.results.contest_not_finished') unless contest.finished?
    raise I18n.t('services.results.already_announced') if contest.results_announced?

    ActiveRecord::Base.transaction do
      calculate_and_save
      contest.announce_results!
    end

    WinnerNotificationJob.perform_later(contest.id)
  end

  def can_announce?
    contest.finished? && !contest.results_announced? && contest.ranking_calculatable?
  end

  private

  def warnings
    warnings = []

    if contest.judge_completion_rate < 100 && (contest.judging_judge_only? || contest.judging_hybrid?)
      warnings << I18n.t('services.results.incomplete_judging', rate: contest.judge_completion_rate)
    end

    if contest.entries.count.zero?
      warnings << I18n.t('services.results.no_entries')
    end

    if contest.judging_judge_only? && contest.contest_judges.empty?
      warnings << I18n.t('services.results.no_judges')
    end

    if contest.judging_judge_only? && contest.evaluation_criteria.empty?
      warnings << I18n.t('services.results.no_criteria')
    end

    if contest.rankings_outdated?
      warnings << I18n.t('services.results.rankings_outdated')
    end

    warnings
  end
end
