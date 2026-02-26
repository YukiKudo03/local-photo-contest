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
    raise "コンテストが終了していません" unless contest.finished?
    raise "結果は既に発表されています" if contest.results_announced?

    ActiveRecord::Base.transaction do
      calculate_and_save
      contest.announce_results!
    end
  end

  def can_announce?
    contest.finished? && !contest.results_announced? && contest.ranking_calculatable?
  end

  private

  def warnings
    warnings = []

    if contest.judge_completion_rate < 100 && (contest.judging_judge_only? || contest.judging_hybrid?)
      warnings << "審査員の採点が#{contest.judge_completion_rate}%しか完了していません"
    end

    if contest.entries.count.zero?
      warnings << "応募作品がありません"
    end

    if contest.judging_judge_only? && contest.contest_judges.empty?
      warnings << "審査員が登録されていません"
    end

    if contest.judging_judge_only? && contest.evaluation_criteria.empty?
      warnings << "評価基準が設定されていません"
    end

    if contest.rankings_outdated?
      warnings << "新しい評価が追加されました。ランキングの再計算をお勧めします"
    end

    warnings
  end
end
