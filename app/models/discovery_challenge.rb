# frozen_string_literal: true

class DiscoveryChallenge < ApplicationRecord
  # Associations
  belongs_to :contest
  has_many :challenge_entries, dependent: :destroy
  has_many :entries, through: :challenge_entries

  # Enums
  enum :status, {
    draft: 0,
    active: 1,
    finished: 2
  }, prefix: :challenge

  # Status type keys for i18n lookup
  STATUS_KEYS = %i[draft active finished].freeze

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :theme, length: { maximum: 100 }, allow_blank: true
  validate :end_date_after_start_date, if: -> { starts_at.present? && ends_at.present? }

  # Scopes
  scope :active_now, -> {
    challenge_active.where("starts_at <= ? AND ends_at >= ?", Time.current, Time.current)
  }
  scope :upcoming, -> {
    challenge_draft.or(challenge_active.where("starts_at > ?", Time.current))
  }
  scope :past, -> {
    challenge_finished.or(challenge_active.where("ends_at < ?", Time.current))
  }
  scope :recent, -> { order(created_at: :desc) }

  # Instance Methods
  def status_name
    I18n.t("models.discovery_challenge.statuses.#{status}")
  end

  def active_now?
    challenge_active? && starts_at <= Time.current && ends_at >= Time.current
  end

  def entries_count
    entries.count
  end

  def discovered_spots_count
    entries.joins(:spot).where(spots: { discovery_status: [ :discovered, :certified ] }).distinct.count("spots.id")
  end

  private

  def end_date_after_start_date
    return unless ends_at <= starts_at

    errors.add(:ends_at, :after_start_date)
  end
end
