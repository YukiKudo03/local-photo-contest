# frozen_string_literal: true

class UserMilestone < ApplicationRecord
  belongs_to :user

  # マイルストーン種別
  TYPES = {
    first_vote: "first_vote",
    first_submission: "first_submission",
    first_contest_published: "first_contest_published",
    first_contest_completed: "first_contest_completed",
    all_entries_judged: "all_entries_judged",
    tutorial_completed: "tutorial_completed"
  }.freeze

  # バッジ情報
  BADGES = {
    "first_vote" => { name: "初投票", icon: "heart", color: "pink" },
    "first_submission" => { name: "フォトグラファー", icon: "camera", color: "indigo" },
    "first_contest_published" => { name: "オーガナイザー", icon: "flag", color: "green" },
    "first_contest_completed" => { name: "マスターオーガナイザー", icon: "trophy", color: "yellow" },
    "all_entries_judged" => { name: "審査完了", icon: "check-circle", color: "blue" },
    "tutorial_completed" => { name: "チュートリアル完了", icon: "academic-cap", color: "purple" }
  }.freeze

  validates :milestone_type, presence: true, inclusion: { in: TYPES.values }
  validates :achieved_at, presence: true

  scope :recent, -> { order(achieved_at: :desc) }

  def badge_info
    BADGES[milestone_type] || { name: milestone_type, icon: "star", color: "gray" }
  end

  class << self
    def achieve!(user, milestone_type, metadata = {})
      return if user.milestones.exists?(milestone_type: milestone_type)

      create!(
        user: user,
        milestone_type: milestone_type,
        achieved_at: Time.current,
        metadata: metadata
      )
    end
  end
end
