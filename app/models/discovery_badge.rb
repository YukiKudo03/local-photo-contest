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

  # Badge name translations
  BADGE_NAMES = {
    pioneer: "開拓者",
    explorer: "探検家",
    curator: "キュレーター",
    master: "マスター"
  }.freeze

  BADGE_DESCRIPTIONS = {
    pioneer: "未開拓エリアへの初投稿を達成",
    explorer: "5つ以上のスポットを発掘",
    curator: "10以上のスポットが認定",
    master: "全ての発掘チャレンジに参加"
  }.freeze

  # Validations
  validates :badge_type, uniqueness: { scope: [ :user_id, :contest_id ], message: "は既に獲得しています" }

  # Scopes
  scope :recent, -> { order(earned_at: :desc) }
  scope :by_type, ->(type) { where(badge_type: type) }

  # Callbacks
  before_create :set_earned_at

  # Instance Methods
  def badge_name
    BADGE_NAMES[badge_type.to_sym]
  end

  def badge_description
    BADGE_DESCRIPTIONS[badge_type.to_sym]
  end

  private

  def set_earned_at
    self.earned_at ||= Time.current
  end
end
