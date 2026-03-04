# frozen_string_literal: true

class AdvancedStatisticsService
  CACHE_TTL = 10.minutes
  CACHE_NAMESPACE = "advanced_stats"

  attr_reader :contest

  def initialize(contest)
    @contest = contest
  end

  # --- Phase 1: Participant Demographics ---

  def repeater_rate
    participants = contest.entries.distinct.pluck(:user_id)
    return 0.0 if participants.empty?

    organizer_contest_ids = Contest.where(user_id: contest.user_id)
                                  .where.not(id: contest.id)
                                  .pluck(:id)
    return 0.0 if organizer_contest_ids.empty?

    repeaters = Entry.where(user_id: participants, contest_id: organizer_contest_ids)
                     .distinct
                     .count(:user_id)

    (repeaters.to_f / participants.size * 100).round(1)
  end

  def new_participant_trend
    first_entries = contest.entries
                           .select("MIN(entries.created_at) as first_entry_at, entries.user_id")
                           .group(:user_id)

    first_entries.each_with_object(Hash.new(0)) do |record, counts|
      date = record.first_entry_at.in_time_zone("Tokyo").to_date
      counts[date] += 1
    end.sort_by { |date, _| date }.to_h
  end

  def cohort_analysis
    participant_ids = contest.entries.distinct.pluck(:user_id)
    return {} if participant_ids.empty?

    users = User.where(id: participant_ids)

    users.group_by { |u| u.created_at.in_time_zone("Tokyo").strftime("%Y-%m") }
         .transform_values { |group| { count: group.size } }
         .sort_by { |month, _| month }
         .to_h
  end

  # --- Phase 3: Area Comparison ---

  def area_comparison
    areas = Area.where(user_id: contest.user_id).ordered
    return [] if areas.empty?

    # Batch-load all counts in single queries
    entries_by_area = contest.entries.where(area_id: areas.map(&:id)).group(:area_id)
    entry_counts = entries_by_area.count
    participant_counts = entries_by_area.distinct.count(:user_id)

    # Batch-load vote counts: get entry_ids grouped by area
    area_entry_ids = contest.entries.where(area_id: areas.map(&:id)).group_by(&:area_id)
    all_entry_ids = area_entry_ids.values.flatten.map(&:id)
    vote_counts_by_entry = Vote.where(entry_id: all_entry_ids).group(:entry_id).count

    areas.map do |area|
      area_entries = area_entry_ids[area.id] || []
      vote_count = area_entries.sum { |e| vote_counts_by_entry[e.id] || 0 }
      entry_count = entry_counts[area.id] || 0
      participant_count = participant_counts[area.id] || 0

      {
        id: area.id,
        name: area.name,
        entries: entry_count,
        votes: vote_count,
        participants: participant_count,
        score: compute_activity_score(entry_count, vote_count, participant_count)
      }
    end
  end

  def area_participant_distribution
    areas = Area.where(user_id: contest.user_id).ordered
    return {} if areas.empty?

    participant_counts = contest.entries.where(area_id: areas.map(&:id))
                                .group(:area_id)
                                .distinct
                                .count(:user_id)
    areas_by_id = areas.index_by(&:id)

    participant_counts.each_with_object({}) do |(area_id, count), result|
      area = areas_by_id[area_id]
      result[area.name] = count if count > 0
    end
  end

  def activity_score(area)
    area_entries = contest.entries.where(area: area)
    entry_count = area_entries.count
    return 0 if entry_count == 0

    entry_ids = area_entries.pluck(:id)
    vote_count = Vote.where(entry_id: entry_ids).count
    participant_count = area_entries.distinct.count(:user_id)

    compute_activity_score(entry_count, vote_count, participant_count)
  end

  # --- Phase 2: Submission Heatmap ---

  def submission_heatmap
    Rails.cache.fetch(cache_key("heatmap"), expires_in: CACHE_TTL) do
      compute_submission_heatmap
    end
  end

  private

  def compute_submission_heatmap
    # Initialize 7x24 zero matrix
    matrix = (0..6).each_with_object({}) do |day, h|
      h[day] = (0..23).each_with_object({}) { |hour, hh| hh[hour] = 0 }
    end

    # Use SQL aggregation with timezone conversion
    entries = contest.entries

    if sqlite?
      # SQLite: store times as UTC, convert to Tokyo (UTC+9) with +9 hours
      rows = entries.group(
        Arel.sql("CAST(strftime('%w', datetime(created_at, '+9 hours')) AS INTEGER)"),
        Arel.sql("CAST(strftime('%H', datetime(created_at, '+9 hours')) AS INTEGER)")
      ).count
    else
      # PostgreSQL: use AT TIME ZONE
      rows = entries.group(
        Arel.sql("EXTRACT(DOW FROM created_at AT TIME ZONE 'Asia/Tokyo')::integer"),
        Arel.sql("EXTRACT(HOUR FROM created_at AT TIME ZONE 'Asia/Tokyo')::integer")
      ).count
    end

    rows.each do |(day, hour), count|
      matrix[day][hour] = count if matrix[day] && matrix[day].key?(hour)
    end

    matrix
  end

  def compute_activity_score(entry_count, vote_count, participant_count)
    (entry_count * 1.0 + vote_count * 0.5 + participant_count * 2.0)
  end

  def sqlite?
    ActiveRecord::Base.connection.adapter_name == "SQLite"
  end

  def cache_key(suffix)
    "#{CACHE_NAMESPACE}/#{contest.id}/#{suffix}"
  end
end
