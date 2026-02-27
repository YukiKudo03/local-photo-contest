# frozen_string_literal: true

module RankingStrategies
  class VoteOnlyStrategy < BaseStrategy
    def calculate(entries)
      max_vote_count = max_votes(entries)
      max_score = max_judge_score

      rankings = entries.map do |entry|
        vote_count = entry.votes.count
        normalized_vote_score = normalize_score(vote_count, max_vote_count)
        judge_avg = calculate_judge_average(entry)

        {
          entry: entry,
          total_score: normalized_vote_score,
          judge_score: normalize_score(judge_avg, max_score.positive? ? max_score : 1),
          vote_score: normalized_vote_score,
          vote_count: vote_count
        }
      end

      assign_ranks(sort_with_tiebreaker(rankings))
    end
  end
end
