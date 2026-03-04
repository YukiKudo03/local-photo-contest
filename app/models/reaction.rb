# frozen_string_literal: true

class Reaction < ApplicationRecord
  belongs_to :user
  belongs_to :entry, counter_cache: :reactions_count

  TYPES = %w[like].freeze

  validates :user_id, uniqueness: { scope: [ :entry_id, :reaction_type ] }
  validates :reaction_type, presence: true, inclusion: { in: TYPES }

  scope :by_user, ->(user) { where(user: user) }
  scope :by_entry, ->(entry) { where(entry: entry) }
  scope :likes, -> { where(reaction_type: "like") }
  scope :recent, -> { order(created_at: :desc) }
end
