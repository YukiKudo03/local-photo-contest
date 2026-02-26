# frozen_string_literal: true

class SpotMergeService
  class MergeError < StandardError; end

  attr_reader :primary_spot, :duplicate_spot

  def initialize(primary_spot, duplicate_spot)
    @primary_spot = primary_spot
    @duplicate_spot = duplicate_spot
  end

  def merge
    validate_merge!

    result = {
      entries_moved: 0,
      votes_moved: 0,
      preserved_discovery: nil
    }

    ActiveRecord::Base.transaction do
      # Preserve discovery info before merge
      result[:preserved_discovery] = preserve_discovery_info

      # Move entries from duplicate to primary
      result[:entries_moved] = move_entries

      # Move votes from duplicate to primary
      result[:votes_moved] = move_votes

      # Mark duplicate as merged
      duplicate_spot.update!(
        merged_into_id: primary_spot.id,
        merged_at: Time.current
      )

      # Update vote counts
      update_vote_counts
    end

    result
  end

  def preview
    {
      entries_to_move: duplicate_spot.entries.count,
      votes_to_move: duplicate_spot.spot_votes.count,
      primary_spot: primary_spot,
      duplicate_spot: duplicate_spot
    }
  end

  private

  def validate_merge!
    if primary_spot.id == duplicate_spot.id
      raise MergeError, "Cannot merge a spot into itself"
    end

    if primary_spot.contest_id != duplicate_spot.contest_id
      raise MergeError, "Spots must be from the same contest"
    end

    if duplicate_spot.merged_into_id.present?
      raise MergeError, "Duplicate spot is already merged"
    end
  end

  def preserve_discovery_info
    return nil unless duplicate_spot.discovered_by_id.present?

    {
      discovered_by_id: duplicate_spot.discovered_by_id,
      discovered_at: duplicate_spot.discovered_at,
      discovery_status: duplicate_spot.discovery_status,
      discovery_comment: duplicate_spot.discovery_comment
    }
  end

  def move_entries
    entries_to_move = duplicate_spot.entries
    count = entries_to_move.count
    entries_to_move.update_all(spot_id: primary_spot.id)
    count
  end

  def move_votes
    votes_to_move = duplicate_spot.spot_votes
    moved_count = 0

    votes_to_move.find_each do |vote|
      # Check if user already voted on primary spot
      existing_vote = primary_spot.spot_votes.find_by(user_id: vote.user_id)

      if existing_vote
        # User already voted on primary, just delete the duplicate vote
        vote.destroy
      else
        # Move vote to primary spot
        vote.update!(spot_id: primary_spot.id)
        moved_count += 1
      end
    end

    moved_count
  end

  def update_vote_counts
    primary_spot.update_column(:votes_count, primary_spot.spot_votes.count)
    duplicate_spot.update_column(:votes_count, duplicate_spot.spot_votes.count)
  end
end
