# frozen_string_literal: true

class UserProfileService
  def initialize(user)
    @user = user
  end

  def portfolio_entries(limit: 6)
    Entry.joins("LEFT JOIN contest_rankings ON contest_rankings.entry_id = entries.id")
         .where(user: @user)
         .order(Arel.sql("contest_rankings.rank ASC NULLS LAST, entries.reactions_count DESC, entries.created_at DESC"))
         .includes(:contest, photo_attachment: :blob)
         .limit(limit)
         .distinct
  end

  def award_history
    ContestRanking.joins(entry: :contest)
                  .where(entries: { user_id: @user.id })
                  .includes(entry: :contest)
                  .order(calculated_at: :desc)
  end

  def stats
    {
      entries_count: @user.entries.count,
      votes_count: @user.votes.count,
      comments_count: @user.comments.count,
      followers_count: @user.followers_count,
      following_count: @user.following_count,
      total_likes_received: Reaction.joins(:entry).where(entries: { user_id: @user.id }).count,
      prizes_won: ContestRanking.joins(:entry).where(entries: { user_id: @user.id }).count
    }
  end
end
