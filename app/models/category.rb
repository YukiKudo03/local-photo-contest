# frozen_string_literal: true

class Category < ApplicationRecord
  # Associations
  has_many :contests, dependent: :nullify

  # Validations
  validates :name, presence: true, uniqueness: true, length: { maximum: 50 }
  validates :description, length: { maximum: 500 }, allow_blank: true

  # Scopes
  scope :ordered, -> { order(position: :asc, name: :asc) }

  # Callbacks
  before_create :set_position

  private

  def set_position
    self.position ||= (Category.maximum(:position) || 0) + 1
  end
end
