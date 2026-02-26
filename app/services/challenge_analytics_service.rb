# frozen_string_literal: true

class ChallengeAnalyticsService
  attr_reader :challenge

  def initialize(challenge)
    @challenge = challenge
  end

  def summary
    entries = challenge_entries

    {
      total_entries: entries.count,
      total_participants: entries.distinct.count(:user_id),
      discovered_spots: discovered_spots_count,
      certified_spots: certified_spots_count,
      challenge_name: challenge.name,
      challenge_status: challenge.status,
      starts_at: challenge.starts_at,
      ends_at: challenge.ends_at
    }
  end

  def participant_ranking(limit: 10)
    Entry.joins(:challenge_entries)
         .where(challenge_entries: { discovery_challenge_id: challenge.id })
         .group(:user_id)
         .select("entries.user_id, COUNT(*) as entries_count")
         .order("entries_count DESC")
         .limit(limit)
         .includes(:user)
         .map do |entry|
           {
             user: entry.user,
             entries_count: entry.entries_count
           }
         end
  end

  def daily_activity
    start_date = challenge.starts_at&.to_date || challenge.created_at.to_date
    end_date = [ challenge.ends_at&.to_date || Date.current, Date.current ].min

    (start_date..end_date).map do |date|
      count = challenge_entries
              .where(created_at: date.beginning_of_day..date.end_of_day)
              .count

      { date: date, count: count }
    end
  end

  def spot_distribution
    spots = Spot.joins(entries: :challenge_entries)
                .where(challenge_entries: { discovery_challenge_id: challenge.id })
                .distinct

    distribution = Hash.new(0)
    spots.each do |spot|
      count = spot.entries.joins(:challenge_entries)
                  .where(challenge_entries: { discovery_challenge_id: challenge.id })
                  .count
      distribution[spot.category.to_sym] += count
    end

    distribution
  end

  def self.compare_challenges(challenges)
    challenges.map do |challenge|
      service = new(challenge)
      summary = service.summary

      {
        id: challenge.id,
        name: challenge.name,
        status: challenge.status,
        total_entries: summary[:total_entries],
        total_participants: summary[:total_participants],
        discovered_spots: summary[:discovered_spots],
        certified_spots: summary[:certified_spots],
        starts_at: challenge.starts_at,
        ends_at: challenge.ends_at
      }
    end
  end

  private

  def challenge_entries
    Entry.joins(:challenge_entries)
         .where(challenge_entries: { discovery_challenge_id: challenge.id })
  end

  def discovered_spots_count
    Spot.joins(entries: :challenge_entries)
        .where(challenge_entries: { discovery_challenge_id: challenge.id })
        .where(discovery_status: :discovered)
        .distinct
        .count
  end

  def certified_spots_count
    Spot.joins(entries: :challenge_entries)
        .where(challenge_entries: { discovery_challenge_id: challenge.id })
        .where(discovery_status: :certified)
        .distinct
        .count
  end
end
