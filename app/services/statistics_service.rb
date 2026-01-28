# frozen_string_literal: true

class StatisticsService
  attr_reader :contest

  def initialize(contest)
    @contest = contest
  end

  # Task 2: サマリーカード用データ
  def summary_stats
    {
      total_entries: total_entries_count,
      total_votes: total_votes_count,
      total_participants: total_participants_count,
      total_spots: total_spots_count,
      entries_change: entries_change_from_yesterday,
      votes_change: votes_change_from_yesterday,
      participants_change: participants_change_from_yesterday,
      spots_change: spots_change_from_yesterday
    }
  end

  # Task 3: 日別応募数（Chartkick対応形式）
  def daily_entries
    contest.entries
           .group_by_day(:created_at, time_zone: "Tokyo")
           .count
  end

  # Task 3: 週別応募数（7日以上の場合のオプション）
  def weekly_entries
    contest.entries
           .group_by_week(:created_at, time_zone: "Tokyo")
           .count
  end

  # Task 3: 応募期間が7日以上かどうか
  def show_weekly_option?
    return false if contest.entries.empty?

    first_entry = contest.entries.minimum(:created_at)
    last_entry = contest.entries.maximum(:created_at)
    return false unless first_entry && last_entry

    (last_entry.to_date - first_entry.to_date).to_i >= 7
  end

  # Task 4: スポット別ランキング（上位limit件）
  def spot_rankings(limit: 10)
    spot_counts = contest.entries
                         .group(:spot_id)
                         .count

    # スポット情報を取得
    spot_ids = spot_counts.keys.compact
    spots_by_id = Spot.where(id: spot_ids).index_by(&:id)

    # ランキングデータを構築
    rankings = spot_counts.map do |spot_id, count|
      if spot_id.nil?
        { spot: nil, name: "スポット未指定", count: count }
      else
        spot = spots_by_id[spot_id]
        { spot: spot, name: spot&.name || "不明", count: count }
      end
    end

    # 降順ソートしてlimit件を返す
    rankings.sort_by { |r| -r[:count] }.first(limit)
  end

  # Task 4: エリア別応募分布（円グラフ用）
  def area_distribution
    return {} unless contest.area.present?

    # スポットにエリア情報がある場合、スポット経由でエリアを取得
    # または直接 entry.area を使用
    area_counts = contest.entries
                         .joins(:spot)
                         .group("spots.name")
                         .count

    # エリアが設定されていない場合は空のハッシュを返す
    return {} if area_counts.empty?

    area_counts
  end

  # Task 5: 日別投票数（Chartkick対応形式）
  def daily_votes
    Vote.joins(entry: :contest)
        .where(entries: { contest_id: contest.id })
        .group_by_day(:created_at, time_zone: "Tokyo")
        .count
  end

  # Task 5: 投票サマリー
  def vote_summary
    votes = Vote.joins(entry: :contest)
                .where(entries: { contest_id: contest.id })

    total = votes.count
    unique_voters = votes.distinct.count(:user_id)
    entries_count = contest.entries.count

    {
      total: total,
      unique_voters: unique_voters,
      average_per_entry: entries_count.positive? ? (total.to_f / entries_count).round(2) : 0
    }
  end

  # Task 5: 上位得票作品（Top limit件）
  def top_voted_entries(limit: 5)
    contest.entries
           .left_joins(:votes)
           .group(:id)
           .select("entries.*, COUNT(votes.id) as votes_count")
           .order(Arel.sql("COUNT(votes.id) DESC"), "entries.created_at ASC")
           .limit(limit)
  end

  # 投票期間が開始しているかどうか
  def voting_started?
    # コンテストが公開されていれば投票可能とみなす
    contest.published? || contest.finished?
  end

  private

  def total_entries_count
    contest.entries.count
  end

  def total_votes_count
    Vote.joins(entry: :contest)
        .where(entries: { contest_id: contest.id })
        .count
  end

  def total_participants_count
    contest.entries.distinct.count(:user_id)
  end

  def total_spots_count
    contest.spots.count
  end

  def entries_change_from_yesterday
    today_count = contest.entries.where(created_at: Date.current.all_day).count
    yesterday_count = contest.entries.where(created_at: Date.yesterday.all_day).count
    return nil if yesterday_count.zero? && today_count.zero?

    today_count - yesterday_count
  end

  def votes_change_from_yesterday
    today_count = Vote.joins(entry: :contest)
                      .where(entries: { contest_id: contest.id })
                      .where(created_at: Date.current.all_day)
                      .count
    yesterday_count = Vote.joins(entry: :contest)
                          .where(entries: { contest_id: contest.id })
                          .where(created_at: Date.yesterday.all_day)
                          .count
    return nil if yesterday_count.zero? && today_count.zero?

    today_count - yesterday_count
  end

  def participants_change_from_yesterday
    today_count = contest.entries.where(created_at: Date.current.all_day).distinct.count(:user_id)
    yesterday_count = contest.entries.where(created_at: Date.yesterday.all_day).distinct.count(:user_id)
    return nil if yesterday_count.zero? && today_count.zero?

    today_count - yesterday_count
  end

  def spots_change_from_yesterday
    today_count = contest.spots.where(created_at: Date.current.all_day).count
    yesterday_count = contest.spots.where(created_at: Date.yesterday.all_day).count
    return nil if yesterday_count.zero? && today_count.zero?

    today_count - yesterday_count
  end
end
