# frozen_string_literal: true

class ContestTemplate < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :source_contest, class_name: "Contest", optional: true
  belongs_to :category, optional: true
  belongs_to :area, optional: true

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :name, uniqueness: { scope: :user_id, message: "は既に使用されています" }
  validates :judging_method, inclusion: { in: Contest.judging_methods.keys }, allow_nil: true
  validates :judge_weight,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_nil: true
  validates :prize_count,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 },
            allow_nil: true
  validates :moderation_threshold,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 },
            allow_nil: true

  # Enums (mirror Contest's enum)
  enum :judging_method, { judge_only: 0, vote_only: 1, hybrid: 2 }, prefix: :judging

  # Scopes
  scope :owned_by, ->(user) { where(user: user) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance Methods
  def owned_by?(other_user)
    user_id == other_user.id
  end

  def source_contest_title
    source_contest&.title || "(削除済み)"
  end
end
