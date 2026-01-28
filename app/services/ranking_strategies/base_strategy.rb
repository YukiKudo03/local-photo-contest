# frozen_string_literal: true

module RankingStrategies
  class BaseStrategy
    attr_reader :contest

    def initialize(contest)
      @contest = contest
    end

    def calculate(entries)
      raise NotImplementedError, "Subclasses must implement #calculate"
    end

    protected

    def sort_with_tiebreaker(rankings)
      rankings.sort_by do |r|
        [
          -r[:total_score],
          -r[:vote_count],
          -(r[:judge_score] || 0),
          r[:entry].created_at
        ]
      end
    end

    def assign_ranks(sorted_rankings)
      sorted_rankings.each_with_index.map do |ranking, index|
        ranking.merge(rank: index + 1)
      end
    end

    def max_votes(entries)
      entries.map { |e| e.votes.count }.max || 1
    end

    def max_judge_score
      contest.evaluation_criteria.sum(:max_score)
    end

    def calculate_judge_average(entry)
      entry.judge_evaluations.average(:score)&.to_f || 0
    end

    def normalize_score(value, max_value)
      return 0 if max_value.zero?
      (value.to_f / max_value) * 100
    end
  end
end
