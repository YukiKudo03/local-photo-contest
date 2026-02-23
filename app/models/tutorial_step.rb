# frozen_string_literal: true

class TutorialStep < ApplicationRecord
  # === 桜井流コンテンツ制約 ===
  MAX_TITLE_LENGTH = 15
  MAX_DESCRIPTION_LENGTH = 40
  MAX_STEPS_PER_TUTORIAL = 5
  RECOMMENDED_DURATION_SECONDS = 5

  # チュートリアルタイプの定義
  TUTORIAL_TYPES = {
    participant_onboarding: "participant_onboarding",
    organizer_onboarding: "organizer_onboarding",
    admin_onboarding: "admin_onboarding",
    judge_onboarding: "judge_onboarding",
    contest_creation: "contest_creation",
    area_management: "area_management",
    judge_invitation: "judge_invitation",
    moderation: "moderation",
    statistics: "statistics",
    photo_submission: "photo_submission",
    voting: "voting"
  }.freeze

  TOOLTIP_POSITIONS = %w[top bottom left right center].freeze

  # アクションタイプ定義
  ACTION_TYPES = {
    observe: "observe",      # 見るだけ
    tap: "tap",              # タップ/クリック
    input: "input",          # 入力
    select: "select",        # 選択
    drag: "drag"             # ドラッグ
  }.freeze

  # Validations
  validates :tutorial_type, presence: true, inclusion: { in: TUTORIAL_TYPES.values }
  validates :step_id, presence: true, uniqueness: { scope: :tutorial_type }
  validates :position, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :title, presence: true,
                    length: { maximum: MAX_TITLE_LENGTH,
                              message: "は#{MAX_TITLE_LENGTH}文字以内で入力してください" }
  validates :description, length: { maximum: MAX_DESCRIPTION_LENGTH,
                                    message: "は#{MAX_DESCRIPTION_LENGTH}文字以内で入力してください" },
                          allow_blank: true
  validates :tooltip_position, inclusion: { in: TOOLTIP_POSITIONS }
  validates :action_type, inclusion: { in: ACTION_TYPES.values }, allow_nil: true
  validates :recommended_duration, numericality: { less_than_or_equal_to: 10 }, allow_nil: true

  validate :title_starts_with_action_verb
  validate :tutorial_step_count_within_limit, on: :create

  # Scopes
  scope :for_type, ->(type) { where(tutorial_type: type).order(:position) }
  scope :ordered, -> { order(:position) }
  scope :skippable, -> { where(skippable: true) }

  # コールバック
  before_validation :set_defaults

  # クラスメソッド
  class << self
    def types_for_role(role)
      case role.to_s
      when "participant"
        %w[participant_onboarding photo_submission voting]
      when "organizer"
        %w[organizer_onboarding contest_creation area_management judge_invitation moderation statistics]
      when "admin"
        %w[admin_onboarding]
      when "judge"
        %w[judge_onboarding]
      else
        []
      end
    end

    def onboarding_type_for_role(role)
      case role.to_s
      when "participant" then "participant_onboarding"
      when "organizer" then "organizer_onboarding"
      when "admin" then "admin_onboarding"
      when "judge" then "judge_onboarding"
      end
    end
  end

  # インスタンスメソッド
  def next_step
    TutorialStep.where(tutorial_type: tutorial_type)
                .where("position > ?", position)
                .order(:position)
                .first
  end

  def previous_step
    TutorialStep.where(tutorial_type: tutorial_type)
                .where("position < ?", position)
                .order(position: :desc)
                .first
  end

  def first_step?
    position == 1
  end

  def last_step?
    next_step.nil?
  end

  def action_verb?
    ACTION_VERBS.any? { |verb| title&.start_with?(verb) }
  end

  def feedback_config
    feedback = success_feedback || {}
    {
      type: feedback["type"] || "default",
      message: feedback["message"],
      animation: feedback["animation"] || "pop",
      sound: feedback["sound"],
      duration: feedback["duration"] || 300
    }
  end

  def as_json_for_tutorial
    {
      id: id,
      step_id: step_id,
      position: position,
      title: title,
      description: description,
      target_selector: target_selector,
      target_path: target_path,
      tooltip_position: tooltip_position,
      options: options,
      action_type: action_type,
      feedback: feedback_config,
      skippable: skippable,
      recommended_duration: recommended_duration,
      is_first: first_step?,
      is_last: last_step?,
      video_url: video_url,
      video_title: video_title
    }
  end

  def has_video?
    video_url.present?
  end

  private

  ACTION_VERBS = %w[
    タップ クリック 選択 入力 確認
    見て 押して 開いて 選んで 入れて
    ドロップ スワイプ スライド 作品
    ハート ナビ ダッシュ スライダー
  ].freeze

  def set_defaults
    self.action_type ||= "observe"
    self.recommended_duration ||= RECOMMENDED_DURATION_SECONDS
    self.skippable = true if skippable.nil?
    self.tooltip_position ||= "bottom"
  end

  def title_starts_with_action_verb
    return if title.blank?
    return if action_verb?

    # 警告のみ（エラーにはしない）
    Rails.logger.warn "[Tutorial] タイトルは動詞で始めることを推奨: #{title}"
  end

  def tutorial_step_count_within_limit
    current_count = TutorialStep.where(tutorial_type: tutorial_type).count
    if current_count >= MAX_STEPS_PER_TUTORIAL
      errors.add(:base, "チュートリアルは最大#{MAX_STEPS_PER_TUTORIAL}ステップまでです")
    end
  end
end
