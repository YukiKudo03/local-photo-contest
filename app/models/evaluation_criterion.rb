# frozen_string_literal: true

class EvaluationCriterion < ApplicationRecord
  self.table_name = "evaluation_criteria"

  # Associations
  belongs_to :contest
  has_many :judge_evaluations, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { maximum: 50 }
  validates :name, uniqueness: { scope: :contest_id, message: :already_registered }
  validates :description, length: { maximum: 500 }, allow_blank: true
  validates :max_score, presence: true,
                        numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 }

  # Scopes
  scope :ordered, -> { order(position: :asc, id: :asc) }

  # Callbacks
  before_create :set_position

  private

  def set_position
    self.position ||= (contest.evaluation_criteria.maximum(:position) || 0) + 1
  end
end
