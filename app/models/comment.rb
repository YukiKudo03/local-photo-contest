# frozen_string_literal: true

class Comment < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :entry

  # Validations
  validates :body, presence: true, length: { maximum: 1000 }

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :oldest, -> { order(created_at: :asc) }

  # Delegation
  delegate :contest, to: :entry
end
