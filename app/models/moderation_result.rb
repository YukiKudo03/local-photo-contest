# frozen_string_literal: true

class ModerationResult < ApplicationRecord
  # Associations
  belongs_to :entry
  belongs_to :reviewed_by, class_name: "User", optional: true

  # Enums
  enum :status, {
    pending: 0,
    approved: 1,
    rejected: 2,
    requires_review: 3
  }, prefix: :moderation

  # Validations
  validates :provider, presence: true
  validates :entry_id, uniqueness: true
  validates :max_confidence, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  # Scopes
  scope :pending_review, -> { where(status: [ :requires_review, :pending ]) }
  scope :reviewed, -> { where.not(reviewed_at: nil) }
  scope :by_provider, ->(provider) { where(provider: provider) }

  # Instance Methods
  def reviewed?
    reviewed_at.present?
  end

  def violation_detected?
    labels.present? && labels.any?
  end

  def mark_reviewed!(reviewer:, approved:, note: nil)
    update!(
      reviewed_by: reviewer,
      reviewed_at: Time.current,
      review_note: note,
      status: approved ? :approved : :rejected
    )
  end
end
