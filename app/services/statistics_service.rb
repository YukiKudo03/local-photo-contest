# frozen_string_literal: true

class StatisticsService
  CACHE_TTL = 5.minutes
  CACHE_NAMESPACE = "statistics"

  DATE_PRESETS = {
    "last_7_days" => -> { [ 7.days.ago.to_date, Date.current ] },
    "last_30_days" => -> { [ 30.days.ago.to_date, Date.current ] },
    "this_week" => -> { [ Date.current.beginning_of_week, Date.current.end_of_week ] },
    "this_month" => -> { [ Date.current.beginning_of_month, Date.current.end_of_month ] }
  }.freeze

  attr_reader :contest, :start_date, :end_date

  def initialize(contest, start_date: nil, end_date: nil, date_preset: nil)
    @contest = contest

    if date_preset.present? && DATE_PRESETS.key?(date_preset)
      @start_date, @end_date = DATE_PRESETS[date_preset].call
    else
      @start_date = start_date
      @end_date = end_date
    end
  end

  # Get date range based on preset
  def date_range_preset(preset)
    return nil unless DATE_PRESETS.key?(preset)
    DATE_PRESETS[preset].call
  end

  # Clear all cached statistics for a contest
  def self.clear_cache(contest)
    cache_keys = %w[summary daily_entries daily_votes spot_rankings vote_summary]
    cache_keys.each do |key|
      Rails.cache.delete("#{CACHE_NAMESPACE}/#{contest.id}/#{key}")
    end
  end

  # Task 2: サマリーカード用データ
  def summary_stats
    # Date range filtering bypasses cache
    if date_range_active?
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
    else
      Rails.cache.fetch(cache_key("summary"), expires_in: CACHE_TTL) do
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
    end
  end

  # Task 3: 日別応募数（Chartkick対応形式）
  def daily_entries
    if date_range_active?
      filtered_entries
        .group_by_day(:created_at, time_zone: "Tokyo")
        .count
    else
      Rails.cache.fetch(cache_key("daily_entries"), expires_in: CACHE_TTL) do
        contest.entries
               .group_by_day(:created_at, time_zone: "Tokyo")
               .count
      end
    end
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
    Rails.cache.fetch(cache_key("spot_rankings"), expires_in: CACHE_TTL) do
      spot_counts = contest.entries
                           .group(:spot_id)
                           .count

      # スポット情報を取得
      spot_ids = spot_counts.keys.compact
      spots_by_id = Spot.where(id: spot_ids).index_by(&:id)

      # ランキングデータを構築
      rankings = spot_counts.map do |spot_id, count|
        if spot_id.nil?
          { spot: nil, name: I18n.t('services.statistics.no_spot'), count: count }
        else
          spot = spots_by_id[spot_id]
          { spot: spot, name: spot&.name || I18n.t('services.statistics.unknown'), count: count }
        end
      end

      # 降順ソートしてlimit件を返す
      rankings.sort_by { |r| -r[:count] }.first(limit)
    end
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
    if date_range_active?
      filtered_votes
        .group_by_day(:created_at, time_zone: "Tokyo")
        .count
    else
      Rails.cache.fetch(cache_key("daily_votes"), expires_in: CACHE_TTL) do
        Vote.joins(entry: :contest)
            .where(entries: { contest_id: contest.id })
            .group_by_day(:created_at, time_zone: "Tokyo")
            .count
      end
    end
  end

  # Task 5: 投票サマリー
  def vote_summary
    Rails.cache.fetch(cache_key("vote_summary"), expires_in: CACHE_TTL) do
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
  end

  # Task 5: 上位得票作品（Top limit件）
  def top_voted_entries(limit: 5)
    base_entries = if date_range_active?
      filtered_entries
    else
      contest.entries
    end

    # Join with votes that may be filtered by date range
    query = base_entries.left_joins(:votes)

    if date_range_active?
      # Filter votes within date range using parameterized conditions
      vote_conditions = []
      vote_params = []

      if start_date
        vote_conditions << "votes.created_at >= ?"
        vote_params << start_date.to_date.beginning_of_day
      end
      if end_date
        vote_conditions << "votes.created_at <= ?"
        vote_params << end_date.to_date.end_of_day
      end

      if vote_conditions.any?
        vote_filter = vote_conditions.join(" AND ")
        sanitized_filter = ActiveRecord::Base.sanitize_sql_array([vote_filter] + vote_params)
        query = query
                  .group(:id)
                  .select("entries.*, COUNT(CASE WHEN #{sanitized_filter} THEN votes.id END) as votes_count")
                  .order(Arel.sql("COUNT(CASE WHEN #{sanitized_filter} THEN votes.id END) DESC"), "entries.created_at ASC")
      else
        query = query
                  .group(:id)
                  .select("entries.*, COUNT(votes.id) as votes_count")
                  .order(Arel.sql("COUNT(votes.id) DESC"), "entries.created_at ASC")
      end
    else
      query = query
                .group(:id)
                .select("entries.*, COUNT(votes.id) as votes_count")
                .order(Arel.sql("COUNT(votes.id) DESC"), "entries.created_at ASC")
    end

    query.limit(limit)
  end

  # 投票期間が開始しているかどうか
  def voting_started?
    # コンテストが公開されていれば投票可能とみなす
    contest.published? || contest.finished?
  end

  private

  def date_range_active?
    start_date.present? || end_date.present?
  end

  def filtered_entries
    query = contest.entries
    query = query.where("entries.created_at >= ?", start_date.to_date.beginning_of_day) if start_date
    query = query.where("entries.created_at <= ?", end_date.to_date.end_of_day) if end_date
    query
  end

  def filtered_votes
    query = Vote.joins(entry: :contest)
                .where(entries: { contest_id: contest.id })
    query = query.where("votes.created_at >= ?", start_date.to_date.beginning_of_day) if start_date
    query = query.where("votes.created_at <= ?", end_date.to_date.end_of_day) if end_date
    query
  end

  def total_entries_count
    if date_range_active?
      filtered_entries.count
    else
      contest.entries.count
    end
  end

  def total_votes_count
    if date_range_active?
      filtered_votes.count
    else
      Vote.joins(entry: :contest)
          .where(entries: { contest_id: contest.id })
          .count
    end
  end

  def total_participants_count
    if date_range_active?
      filtered_entries.distinct.count(:user_id)
    else
      contest.entries.distinct.count(:user_id)
    end
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

  def cache_key(suffix)
    "#{CACHE_NAMESPACE}/#{contest.id}/#{suffix}"
  end
end
