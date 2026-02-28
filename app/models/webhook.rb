# frozen_string_literal: true

class Webhook < ApplicationRecord
  VALID_EVENTS = %w[
    entry.created
    vote.created
    contest.status_changed
  ].freeze

  belongs_to :user
  belongs_to :contest, optional: true
  has_many :webhook_deliveries, dependent: :destroy

  validates :url, presence: true
  validate :url_must_be_https
  validate :event_types_must_be_valid

  scope :active, -> { where(active: true) }

  def self.for_event(event_name)
    active.select { |w| w.subscribes_to?(event_name) }
  end

  def parsed_event_types
    case event_types
    when String then JSON.parse(event_types)
    when Array then event_types
    else []
    end
  rescue JSON::ParserError
    []
  end

  def subscribes_to?(event_name)
    parsed_event_types.include?(event_name.to_s)
  end

  def disable_if_failing!
    update!(active: false) if failures_count >= 10
  end

  def compute_signature(payload)
    OpenSSL::HMAC.hexdigest("SHA256", secret.to_s, payload.to_s)
  end

  private

  def url_must_be_https
    return if url.blank?
    uri = URI.parse(url)
    errors.add(:url, :must_be_https) unless uri.scheme == "https"
  rescue URI::InvalidURIError
    errors.add(:url, :invalid)
  end

  def event_types_must_be_valid
    types = parsed_event_types
    return if types.empty?
    invalid = types - VALID_EVENTS
    errors.add(:event_types, :invalid_events) if invalid.any?
  end
end
