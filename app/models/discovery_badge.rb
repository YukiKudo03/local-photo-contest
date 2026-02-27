# frozen_string_literal: true

class DiscoveryBadge < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :contest

  # Enums
  enum :badge_type, {
    pioneer: 0,   # 開拓者（未開拓エリアへの初投稿）
    explorer: 1,  # 探検家（5スポット発掘）
    curator: 2,   # キュレーター（10スポット認定）
    master: 3     # マスター（全チャレンジ参加）
  }, prefix: :badge

  # Badge type keys for i18n lookup
  BADGE_TYPES = %i[pioneer explorer curator master].freeze

  # Validations
  validates :badge_type, uniqueness: { scope: [ :user_id, :contest_id ], message: :already_earned }

  # Scopes
  scope :recent, -> { order(earned_at: :desc) }
  scope :by_type, ->(type) { where(badge_type: type) }

  # Callbacks
  before_create :set_earned_at

  # Instance Methods
  def badge_name
    I18n.t("models.discovery_badge.names.#{badge_type}")
  end

  def badge_description
    I18n.t("models.discovery_badge.descriptions.#{badge_type}")
  end

  private

  def set_earned_at
    self.earned_at ||= Time.current
  end
end
