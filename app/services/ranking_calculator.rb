# frozen_string_literal: true

class RankingCalculator
  attr_reader :contest

  def initialize(contest)
    @contest = contest
    @strategy = select_strategy
  end

  def calculate
    entries = contest.entries.includes(:votes, :judge_evaluations)
    rankings = @strategy.calculate(entries)
    save_rankings(rankings)
    rankings
  end

  def preview
    entries = contest.entries.includes(:votes, :judge_evaluations)
    @strategy.calculate(entries)
  end

  private

  def select_strategy
    case contest.judging_method
    when "judge_only"
      RankingStrategies::JudgeOnlyStrategy.new(contest)
    when "vote_only"
      RankingStrategies::VoteOnlyStrategy.new(contest)
    when "hybrid"
      RankingStrategies::HybridStrategy.new(contest, contest.judge_weight)
    else
      RankingStrategies::JudgeOnlyStrategy.new(contest)
    end
  end

  def save_rankings(rankings)
    ActiveRecord::Base.transaction do
      contest.contest_rankings.destroy_all

      calculated_at = Time.current

      rankings.each do |ranking|
        ContestRanking.create!(
          contest: contest,
          entry: ranking[:entry],
          rank: ranking[:rank],
          total_score: ranking[:total_score],
          judge_score: ranking[:judge_score],
          vote_score: ranking[:vote_score],
          vote_count: ranking[:vote_count],
          calculated_at: calculated_at
        )
      end
    end
  end
end
