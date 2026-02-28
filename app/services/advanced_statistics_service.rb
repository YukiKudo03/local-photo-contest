# frozen_string_literal: true

class AdvancedStatisticsService
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

    areas.map do |area|
      area_entries = contest.entries.where(area: area)
      entry_ids = area_entries.pluck(:id)

      {
        id: area.id,
        name: area.name,
        entries: area_entries.count,
        votes: entry_ids.any? ? Vote.where(entry_id: entry_ids).count : 0,
        participants: area_entries.distinct.count(:user_id),
        score: activity_score(area)
      }
    end
  end

  def area_participant_distribution
    areas = Area.where(user_id: contest.user_id).ordered
    return {} if areas.empty?

    areas.each_with_object({}) do |area, result|
      count = contest.entries.where(area: area).distinct.count(:user_id)
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

    (entry_count * 1.0 + vote_count * 0.5 + participant_count * 2.0)
  end

  # --- Phase 2: Submission Heatmap ---

  def submission_heatmap
    matrix = (0..6).each_with_object({}) do |day, h|
      h[day] = (0..23).each_with_object({}) { |hour, hh| hh[hour] = 0 }
    end

    contest.entries.find_each do |entry|
      tokyo_time = entry.created_at.in_time_zone("Tokyo")
      matrix[tokyo_time.wday][tokyo_time.hour] += 1
    end

    matrix
  end
end
