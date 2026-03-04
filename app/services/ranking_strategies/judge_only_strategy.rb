# frozen_string_literal: true

module RankingStrategies
  class JudgeOnlyStrategy < BaseStrategy
    def calculate(entries)
      max_score = max_judge_score
      max_vote_count = max_votes(entries)

      rankings = entries.map do |entry|
        judge_avg = calculate_judge_average(entry)
        normalized_judge_score = normalize_score(judge_avg, max_score.positive? ? max_score : 1)
        vote_count = entry.votes_count

        {
          entry: entry,
          total_score: normalized_judge_score,
          judge_score: normalized_judge_score,
          vote_score: normalize_score(vote_count, max_vote_count),
          vote_count: vote_count
        }
      end

      assign_ranks(sort_with_tiebreaker(rankings))
    end
  end
end
