# frozen_string_literal: true

class ChallengeEntry < ApplicationRecord
  # Associations
  belongs_to :discovery_challenge
  belongs_to :entry

  # Validations
  validates :entry_id, uniqueness: { scope: :discovery_challenge_id, message: :already_participating }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }

  # Delegate
  delegate :contest, to: :discovery_challenge
end
