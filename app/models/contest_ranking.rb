# frozen_string_literal: true

class ContestRanking < ApplicationRecord
  # Associations
  belongs_to :contest
  belongs_to :entry
  has_one_attached :certificate_pdf

  # Validations
  validates :rank, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :total_score, presence: true
  validates :calculated_at, presence: true
  validates :entry_id, uniqueness: { scope: :contest_id, message: :already_ranked }
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
    when 1 then I18n.t('ranks.grand_prize')
    when 2 then I18n.t('ranks.excellence')
    when 3 then I18n.t('ranks.merit')
    else I18n.t('ranks.award')
    end
  end

  def certificate_generated?
    certificate_generated_at.present?
  end

  def winner_notified?
    winner_notified_at.present?
  end
end
