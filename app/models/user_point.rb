# frozen_string_literal: true

class UserPoint < ApplicationRecord
  belongs_to :user
  belongs_to :source, polymorphic: true, optional: true

  POINT_VALUES = {
    "submit_entry" => 10,
    "vote" => 1,
    "comment" => 3,
    "prize_1st" => 50,
    "prize_2nd" => 30,
    "prize_3rd" => 20,
    "prize_other" => 10,
    "milestone_achieved" => 5
  }.freeze

  ACTION_TYPES = POINT_VALUES.keys.freeze

  validates :user, presence: true
  validates :points, presence: true, numericality: { greater_than: 0 }
  validates :action_type, presence: true, inclusion: { in: ACTION_TYPES }
  validates :earned_at, presence: true

  scope :for_period, ->(start_at, end_at) { where(earned_at: start_at..end_at) }
  scope :by_action_type, ->(type) { where(action_type: type) }
  scope :recent, -> { order(earned_at: :desc) }
end
