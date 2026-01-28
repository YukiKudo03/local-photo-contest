# frozen_string_literal: true

class SpotVote < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :spot, counter_cache: :votes_count

  # Validations
  validates :user_id, uniqueness: { scope: :spot_id, message: "は既にこのスポットに投票しています" }
  validate :spot_must_be_certified

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user) { where(user: user) }

  private

  def spot_must_be_certified
    return unless spot.present?
    return if spot.discovery_certified? || spot.discovery_organizer_created?

    errors.add(:spot, "は認定済みスポットのみ投票可能です")
  end
end
