# frozen_string_literal: true

module RankingStrategies
  class HybridStrategy < BaseStrategy
    attr_reader :judge_weight, :vote_weight

    def initialize(contest, judge_weight_percent = nil)
      super(contest)
      @judge_weight = (judge_weight_percent || contest.judge_weight || 70) / 100.0
      @vote_weight = 1 - @judge_weight
    end

    def calculate(entries)
      max_score = max_judge_score
      max_vote_count = max_votes(entries)

      rankings = entries.map do |entry|
        judge_avg = calculate_judge_average(entry)
        vote_count = entry.votes.count

        normalized_judge_score = normalize_score(judge_avg, max_score.positive? ? max_score : 1)
        normalized_vote_score = normalize_score(vote_count, max_vote_count)

        total_score = (normalized_judge_score * @judge_weight) + (normalized_vote_score * @vote_weight)

        {
          entry: entry,
          total_score: total_score,
          judge_score: normalized_judge_score,
          vote_score: normalized_vote_score,
          vote_count: vote_count
        }
      end

      assign_ranks(sort_with_tiebreaker(rankings))
    end
  end
end
