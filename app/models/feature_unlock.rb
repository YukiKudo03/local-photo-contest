# frozen_string_literal: true

class FeatureUnlock < ApplicationRecord
  belongs_to :user

  # 機能キー定義
  FEATURES = {
    # 参加者機能
    submit_entry: "submit_entry",
    comment: "comment",
    share: "share",

    # 運営者機能
    create_contest_custom: "create_contest_custom",
    area_management: "area_management",
    judge_invitation: "judge_invitation",
    evaluation_criteria: "evaluation_criteria",
    statistics: "statistics",
    result_announcement: "result_announcement",

    # 管理者機能
    advanced_moderation: "advanced_moderation",
    system_settings: "system_settings"
  }.freeze

  # 機能開放トリガー
  UNLOCK_TRIGGERS = {
    "submit_entry" => :first_vote,
    "comment" => :first_vote,
    "create_contest_custom" => :first_contest_published,
    "area_management" => :first_contest_published,
    "judge_invitation" => :first_contest_published,
    "evaluation_criteria" => :first_contest_completed,
    "statistics" => :first_contest_completed,
    "result_announcement" => :first_contest_completed
  }.freeze

  validates :feature_key, presence: true, inclusion: { in: FEATURES.values }
  validates :unlocked_at, presence: true

  scope :for_feature, ->(key) { where(feature_key: key) }

  class << self
    def unlock!(user, feature_key, trigger = nil)
      return if user.feature_unlocks.exists?(feature_key: feature_key)

      create!(
        user: user,
        feature_key: feature_key,
        unlocked_at: Time.current,
        unlock_trigger: trigger
      )
    end

    def unlocked?(user, feature_key)
      user.feature_unlocks.exists?(feature_key: feature_key)
    end
  end
end
