# frozen_string_literal: true

class Vote < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :entry

  # Validations
  validates :user_id, uniqueness: { scope: :entry_id, message: "は既にこの作品に投票しています" }
  validate :cannot_vote_own_entry
  validate :contest_accepting_votes, on: :create

  # Callbacks
  after_create_commit :broadcast_vote_update
  after_destroy_commit :broadcast_vote_update
  after_commit :clear_statistics_cache, on: [ :create, :destroy ]

  # Scopes
  scope :by_user, ->(user) { where(user: user) }
  scope :by_entry, ->(entry) { where(entry: entry) }
  scope :recent, -> { order(created_at: :desc) }

  # Delegate contest to entry for easier access
  delegate :contest, to: :entry

  private

  def cannot_vote_own_entry
    return unless entry && user

    if entry.user_id == user_id
      errors.add(:base, "自分の作品には投票できません")
    end
  end

  def contest_accepting_votes
    return unless entry&.contest

    unless entry.contest.accepting_entries?
      errors.add(:base, "このコンテストは現在投票を受け付けていません")
    end
  end

  def broadcast_vote_update
    NotificationBroadcaster.vote_update(entry)
  rescue => e
    Rails.logger.error("Failed to broadcast vote update: #{e.message}")
  end

  def clear_statistics_cache
    StatisticsService.clear_cache(contest)
  rescue => e
    Rails.logger.error("Failed to clear statistics cache: #{e.message}")
  end
end
