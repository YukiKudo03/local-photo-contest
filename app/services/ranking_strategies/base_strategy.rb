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

    # Standard competition ranking (1224 ranking)
    # Entries with identical scores (total_score, vote_count, judge_score) get the same rank
    # If any of these differ, entries get different ranks based on sort order
    # Example: scores [100, 100, 80, 80, 50] → ranks [1, 1, 3, 3, 5]
    def assign_ranks(sorted_rankings)
      return [] if sorted_rankings.empty?

      result = []
      current_rank = 1

      sorted_rankings.each_with_index do |ranking, index|
        if index.zero?
          result << ranking.merge(rank: current_rank)
        else
          previous = result[index - 1]
          # Compare all score components to determine if this is a tie
          # Only assign same rank if total_score, vote_count, AND judge_score are all identical
          if same_scores?(ranking, previous)
            # Same scores as previous entry, assign same rank
            result << ranking.merge(rank: previous[:rank])
          else
            # Different scores, assign current position + 1
            current_rank = index + 1
            result << ranking.merge(rank: current_rank)
          end
        end
      end

      result
    end

    def same_scores?(ranking1, ranking2)
      ranking1[:total_score] == ranking2[:total_score] &&
        ranking1[:vote_count] == ranking2[:vote_count] &&
        (ranking1[:judge_score] || 0) == (ranking2[:judge_score] || 0)
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
