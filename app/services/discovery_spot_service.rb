# frozen_string_literal: true

class DiscoverySpotService
  NEARBY_RADIUS_METERS = 50
  EARTH_RADIUS_KM = 6371

  class << self
    # Create a new discovered spot from an entry
    # Note: entry may not be persisted yet, so we don't update entry.spot here
    # The caller is responsible for setting entry.spot = spot after calling this
    def create_discovered_spot(entry:, name:, latitude:, longitude:, comment: nil, category: :other)
      contest = entry.contest
      user = entry.user

      spot = contest.spots.build(
        name: name,
        latitude: latitude.presence,
        longitude: longitude.presence,
        discovery_comment: comment,
        category: category,
        discovery_status: :discovered,
        discovered_by: user,
        discovered_at: Time.current
      )

      spot.save!

      # Send notification to organizer (async-safe, won't rollback transaction)
      notify_organizer_of_discovery(spot)

      spot
    end

    # Certify a discovered spot
    def certify_spot(spot:, user:)
      raise ArgumentError, "Spot is not pending certification" unless spot.discovery_discovered?

      ActiveRecord::Base.transaction do
        spot.certify!(user)

        # Notify the discoverer
        if spot.discovered_by.present?
          Notification.create!(
            user: spot.discovered_by,
            notifiable: spot,
            notification_type: "spot_certified",
            title: "スポットが認定されました",
            body: "あなたが発掘した「#{spot.name}」が認定されました！"
          )
        end

        # Check and award badges
        check_and_award_badges(spot.discovered_by, spot.contest) if spot.discovered_by.present?
      end

      spot
    end

    # Reject a discovered spot
    def reject_spot(spot:, user:, reason:)
      raise ArgumentError, "Spot is not pending certification" unless spot.discovery_discovered?
      raise ArgumentError, "Rejection reason is required" if reason.blank?

      ActiveRecord::Base.transaction do
        spot.reject!(user, reason)

        # Notify the discoverer
        if spot.discovered_by.present?
          Notification.create!(
            user: spot.discovered_by,
            notifiable: spot,
            notification_type: "spot_rejected",
            title: "スポットが却下されました",
            body: "発掘スポット「#{spot.name}」が却下されました。理由: #{reason}"
          )
        end
      end

      spot
    end

    # Merge multiple spots into one
    def merge_spots(target:, sources:)
      ActiveRecord::Base.transaction do
        sources.each do |source|
          # Move entries from source to target
          source.entries.update_all(spot_id: target.id)

          # Move votes from source to target
          source.spot_votes.each do |vote|
            # Only move if user hasn't already voted for target
            unless target.spot_votes.exists?(user_id: vote.user_id)
              vote.update!(spot_id: target.id)
            end
          end

          # Delete the source spot
          source.destroy!
        end

        # Update target's votes_count
        target.update_column(:votes_count, target.spot_votes.count)
      end

      target.reload
    end

    # Find spots within a radius (in meters) of the given coordinates
    def find_nearby_spots(contest:, latitude:, longitude:, radius_m: NEARBY_RADIUS_METERS)
      return [] unless latitude.present? && longitude.present?

      radius_km = radius_m / 1000.0
      lat = latitude.to_f
      lng = longitude.to_f

      # Calculate bounding box for initial filtering
      lat_delta = radius_km / 111.0 # 1 degree latitude ≈ 111 km
      lng_delta = radius_km / (111.0 * Math.cos(lat * Math::PI / 180))

      spots = contest.spots
                     .with_coordinates
                     .where(latitude: (lat - lat_delta)..(lat + lat_delta))
                     .where(longitude: (lng - lng_delta)..(lng + lng_delta))

      # Filter by actual distance using Haversine formula
      spots.select do |spot|
        haversine_distance(lat, lng, spot.latitude.to_f, spot.longitude.to_f) <= radius_km
      end
    end

    # Get discovery statistics for a contest
    def discovery_statistics(contest)
      spots = contest.spots

      {
        total_spots: spots.count,
        organizer_created: spots.discovery_organizer_created.count,
        discovered: spots.discovery_discovered.count,
        certified: spots.discovery_certified.count,
        rejected: spots.discovery_rejected.count,
        pending_certification: spots.pending_certification.count,
        active_discoverers: spots.where.not(discovered_by_id: nil).distinct.count(:discovered_by_id),
        total_spot_votes: SpotVote.joins(:spot).where(spots: { contest_id: contest.id }).count,
        top_voted_spots: top_voted_spots(contest, 10),
        top_discoverers: top_discoverers(contest, 10),
        discovery_by_area: discovery_by_area(contest),
        challenges_stats: challenges_stats(contest)
      }
    end

    # Get discovery ranking for a contest
    def discovery_ranking(contest, limit: 10)
      User.joins(:discovered_spots)
          .where(spots: { contest_id: contest.id, discovery_status: :certified })
          .group("users.id")
          .select("users.*, COUNT(spots.id) as certified_count")
          .order("certified_count DESC")
          .limit(limit)
    end

    private

    def haversine_distance(lat1, lng1, lat2, lng2)
      # Convert to radians
      lat1_rad = lat1 * Math::PI / 180
      lat2_rad = lat2 * Math::PI / 180
      delta_lat = (lat2 - lat1) * Math::PI / 180
      delta_lng = (lng2 - lng1) * Math::PI / 180

      a = Math.sin(delta_lat / 2)**2 +
          Math.cos(lat1_rad) * Math.cos(lat2_rad) *
          Math.sin(delta_lng / 2)**2

      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

      EARTH_RADIUS_KM * c
    end

    def notify_organizer_of_discovery(spot)
      Notification.create!(
        user: spot.contest.user,
        notifiable: spot,
        notification_type: "spot_discovered",
        title: "新しいスポットが発掘されました",
        body: "「#{spot.name}」が発掘されました。審査をお願いします。"
      )
    rescue => e
      Rails.logger.error("Failed to notify organizer of spot discovery: #{e.message}")
    end

    def check_and_award_badges(user, contest)
      certified_count = user.discovered_spots.where(contest: contest, discovery_status: :certified).count

      # Explorer badge: 5+ spots discovered
      if certified_count >= 5 && !user.discovery_badges.exists?(contest: contest, badge_type: :explorer)
        DiscoveryBadge.create!(user: user, contest: contest, badge_type: :explorer)
      end

      # Curator badge: 10+ spots certified
      if certified_count >= 10 && !user.discovery_badges.exists?(contest: contest, badge_type: :curator)
        DiscoveryBadge.create!(user: user, contest: contest, badge_type: :curator)
      end
    rescue => e
      Rails.logger.error("Failed to award badge: #{e.message}")
    end

    def top_voted_spots(contest, limit)
      contest.spots
             .certified_or_organizer
             .where("votes_count > 0")
             .order(votes_count: :desc)
             .limit(limit)
    end

    def top_discoverers(contest, limit)
      User.joins(:discovered_spots)
          .where(spots: { contest_id: contest.id, discovery_status: [ :discovered, :certified ] })
          .group("users.id")
          .select("users.*, COUNT(spots.id) as discovery_count")
          .order("discovery_count DESC")
          .limit(limit)
    end

    def discovery_by_area(contest)
      # Group spots by their general area (using a grid approach)
      # This is a simplified version - in production you'd use proper spatial indexing
      contest.spots
             .with_coordinates
             .group_by { |spot| [ (spot.latitude.to_f * 100).round / 100.0, (spot.longitude.to_f * 100).round / 100.0 ] }
             .transform_values(&:count)
    end

    def challenges_stats(contest)
      contest.discovery_challenges.map do |challenge|
        {
          id: challenge.id,
          name: challenge.name,
          status: challenge.status,
          entries_count: challenge.entries_count,
          discovered_spots_count: challenge.discovered_spots_count
        }
      end
    end
  end
end
