# frozen_string_literal: true

class ActivityFeedService
  PER_PAGE = 20

  def initialize(user)
    @user = user
  end

  def feed(page: 1)
    followed_ids = @user.active_follows.pluck(:followed_id)
    return { entries: Entry.none, rankings: ContestRanking.none } if followed_ids.empty?

    entries = Entry.where(user_id: followed_ids)
                   .includes(:user, :contest, photo_attachment: :blob)
                   .order(created_at: :desc)
                   .limit(PER_PAGE)
                   .offset((page.to_i - 1) * PER_PAGE)

    rankings = ContestRanking.joins(:entry)
                             .where(entries: { user_id: followed_ids })
                             .where(rank: 1..3)
                             .includes(entry: [ :user, :contest ])
                             .order(calculated_at: :desc)
                             .limit(PER_PAGE)
                             .offset((page.to_i - 1) * PER_PAGE)

    { entries: entries, rankings: rankings }
  end
end
