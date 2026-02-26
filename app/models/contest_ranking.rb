# frozen_string_literal: true

class ContestRanking < ApplicationRecord
  # Associations
  belongs_to :contest
  belongs_to :entry

  # Validations
  validates :rank, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :total_score, presence: true
  validates :calculated_at, presence: true
  validates :entry_id, uniqueness: { scope: :contest_id, message: "は既にランキングに登録されています" }
  # Note: rank uniqueness removed to support standard competition ranking
  # where entries with identical scores receive the same rank

  # Scopes
  scope :for_contest, ->(contest) { where(contest: contest) }
  scope :ordered, -> { order(rank: :asc) }
  scope :top, ->(limit) { ordered.limit(limit) }

  # Instance Methods
  def prize?
    rank <= (contest&.prize_count || 3)
  end

  def prize_label
    case rank
    when 1 then "最優秀賞"
    when 2 then "優秀賞"
    when 3 then "準優秀賞"
    else "入賞"
    end
  end
end
