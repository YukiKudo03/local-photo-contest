# frozen_string_literal: true

class Spot < ApplicationRecord
  # Associations
  belongs_to :contest
  belongs_to :discovered_by, class_name: "User", optional: true
  belongs_to :certified_by, class_name: "User", optional: true
  has_many :entries, dependent: :nullify
  has_many :spot_votes, dependent: :destroy

  # Enums
  enum :category, {
    restaurant: 0,      # 飲食店
    retail: 1,          # 小売店
    service: 2,         # サービス業
    landmark: 3,        # 名所・ランドマーク
    public_facility: 4, # 公共施設
    park: 5,            # 公園・広場
    temple_shrine: 6,   # 寺社仏閣
    other: 99           # その他
  }

  enum :discovery_status, {
    organizer_created: 0, # 主催者が作成
    discovered: 1,        # 参加者が発掘（審査中）
    certified: 2,         # 認定済み
    rejected: 3           # 却下
  }, prefix: :discovery

  # Category name translations
  CATEGORY_NAMES = {
    restaurant: "飲食店",
    retail: "小売店",
    service: "サービス業",
    landmark: "名所・ランドマーク",
    public_facility: "公共施設",
    park: "公園・広場",
    temple_shrine: "寺社仏閣",
    other: "その他"
  }.freeze

  DISCOVERY_STATUS_NAMES = {
    organizer_created: "主催者作成",
    discovered: "発掘中",
    certified: "認定済み",
    rejected: "却下"
  }.freeze

  # Validations
  validates :name, presence: true,
                   length: { maximum: 100 },
                   uniqueness: { scope: :contest_id, message: "は既にこのコンテストに登録されています" }
  validates :address, length: { maximum: 200 }, allow_blank: true
  validates :description, length: { maximum: 1000 }, allow_blank: true
  validates :category, presence: true

  # Scopes
  scope :ordered, -> { order(position: :asc, id: :asc) }
  scope :with_coordinates, -> { where.not(latitude: nil, longitude: nil) }
  scope :pending_certification, -> { where(discovery_status: :discovered) }
  scope :certified_or_organizer, -> { where(discovery_status: [ :organizer_created, :certified ]) }
  scope :discovered_by_user, ->(user) { where(discovered_by: user) }

  # Callbacks
  before_create :set_position

  # Instance Methods
  def coordinates
    return nil unless latitude.present? && longitude.present?

    [ latitude.to_f, longitude.to_f ]
  end

  def category_name
    CATEGORY_NAMES[category.to_sym]
  end

  def discovery_status_name
    DISCOVERY_STATUS_NAMES[discovery_status.to_sym]
  end

  def discovered?
    discovered_by_id.present?
  end

  def certify!(user)
    update!(
      discovery_status: :certified,
      certified_by: user,
      certified_at: Time.current
    )
  end

  def reject!(user, reason)
    update!(
      discovery_status: :rejected,
      certified_by: user,
      certified_at: Time.current,
      rejection_reason: reason
    )
  end

  def voted_by?(user)
    spot_votes.exists?(user: user)
  end

  def voteable?
    discovery_organizer_created? || discovery_certified?
  end

  private

  def set_position
    self.position ||= (contest.spots.maximum(:position) || 0) + 1
  end
end
