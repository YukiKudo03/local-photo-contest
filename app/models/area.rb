# frozen_string_literal: true

class Area < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :contests, dependent: :restrict_with_error
  has_many :entries, dependent: :nullify

  # Validations
  validates :name, presence: true,
                   uniqueness: { scope: :user_id, message: :duplicate_name },
                   length: { maximum: 50 }
  validates :prefecture, length: { maximum: 20 }, allow_blank: true
  validates :city, length: { maximum: 50 }, allow_blank: true
  validates :address, length: { maximum: 200 }, allow_blank: true
  validates :description, length: { maximum: 2000 }, allow_blank: true
  validate :valid_boundary_geojson, if: -> { boundary_geojson.present? }

  # Scopes
  scope :ordered, -> { order(position: :asc, name: :asc) }
  scope :for_user, ->(user) { where(user: user) }

  # Callbacks
  before_create :set_position

  # Instance Methods
  def full_address
    [ prefecture, city, address ].compact_blank.join("")
  end

  def has_boundary?
    boundary_geojson.present?
  end

  def boundary_polygon
    return nil unless has_boundary?

    begin
      JSON.parse(boundary_geojson)
    rescue JSON::ParserError
      nil
    end
  end

  def center_coordinates
    return nil unless latitude.present? && longitude.present?

    [ latitude.to_f, longitude.to_f ]
  end

  def owned_by?(other_user)
    user_id == other_user&.id
  end

  private

  def set_position
    self.position ||= (Area.where(user_id: user_id).maximum(:position) || 0) + 1
  end

  def valid_boundary_geojson
    JSON.parse(boundary_geojson)
  rescue JSON::ParserError
    errors.add(:boundary_geojson, :invalid_json)
  end
end
