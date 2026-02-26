# frozen_string_literal: true

module TutorialTrackable
  extend ActiveSupport::Concern

  PARTICIPANT_BASE_FEATURES = %w[view_contests view_entries vote].freeze
  ORGANIZER_BASE_FEATURES = %w[view_dashboard create_contest_from_template basic_moderation].freeze
  ADMIN_BASE_FEATURES = %w[view_admin_dashboard manage_users manage_contests].freeze

  included do
    has_many :milestones, class_name: "UserMilestone", dependent: :destroy
    has_many :feature_unlocks, dependent: :destroy

    # 機能レベル
    enum :feature_level, {
      beginner: "beginner",
      intermediate: "intermediate",
      advanced: "advanced"
    }, prefix: true
  end

  # === 機能アクセス ===

  def can_access_feature?(feature_key)
    # 基本機能は常にアクセス可能
    return true if basic_feature?(feature_key)

    # アンロック済みならアクセス可能
    feature_unlocks.exists?(feature_key: feature_key)
  end

  def available_features
    base_features = case role
    when "participant" then PARTICIPANT_BASE_FEATURES
    when "organizer" then ORGANIZER_BASE_FEATURES
    when "admin" then ADMIN_BASE_FEATURES
    else []
    end

    base_features + feature_unlocks.pluck(:feature_key)
  end

  # === マイルストーン ===

  def achieved_milestone?(milestone_type)
    milestones.exists?(milestone_type: milestone_type)
  end

  def recent_milestones(limit = 5)
    milestones.recent.limit(limit)
  end

  # === 機能レベル更新 ===

  def update_feature_level!
    new_level = calculate_feature_level
    update!(feature_level: new_level) if feature_level != new_level
  end

  private

  def basic_feature?(feature_key)
    case role
    when "participant" then PARTICIPANT_BASE_FEATURES.include?(feature_key)
    when "organizer" then ORGANIZER_BASE_FEATURES.include?(feature_key)
    when "admin" then true
    else false
    end
  end

  def calculate_feature_level
    case role
    when "organizer"
      if achieved_milestone?("first_contest_completed")
        "advanced"
      elsif achieved_milestone?("first_contest_published")
        "intermediate"
      else
        "beginner"
      end
    when "participant"
      if achieved_milestone?("first_submission")
        "intermediate"
      else
        "beginner"
      end
    else
      "advanced"
    end
  end
end
