# frozen_string_literal: true

class Tag < ApplicationRecord
  has_many :entry_tags, dependent: :destroy
  has_many :entries, through: :entry_tags

  validates :name, presence: true, uniqueness: true, length: { maximum: 100 }
  validates :category, length: { maximum: 50 }

  scope :popular, -> { order(entries_count: :desc) }
  scope :by_category, ->(category) { where(category: category) }
  scope :alphabetical, -> { order(:name) }
end
