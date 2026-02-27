class TutorialProgress < ApplicationRecord
  belongs_to :user

  # Validations
  validates :tutorial_type, presence: true,
                            inclusion: { in: TutorialStep::TUTORIAL_TYPES.values }
  validates :user_id, uniqueness: { scope: :tutorial_type,
                                    message: :already_exists }

  # Scopes
  scope :completed, -> { where(completed: true) }
  scope :in_progress, -> { where(completed: false, skipped: false).where.not(started_at: nil) }
  scope :skipped, -> { where(skipped: true) }
  scope :not_started, -> { where(started_at: nil) }
  scope :for_type, ->(type) { find_by(tutorial_type: type) }

  # コールバック
  before_save :update_step_data, if: :current_step_id_changed?

  # 開始
  def start!
    return if started_at.present?

    first_step = TutorialStep.for_type(tutorial_type).first
    update!(
      started_at: Time.current,
      current_step_id: first_step&.step_id
    )
  end

  # 次のステップへ進む
  def advance!
    return if completed? || skipped?

    current = current_step
    return complete! if current.nil? || current.last_step?

    next_step = current.next_step
    update!(current_step_id: next_step.step_id)
  end

  # 特定のステップへ移動
  def advance_to!(step_id)
    step = TutorialStep.find_by(tutorial_type: tutorial_type, step_id: step_id)
    return false unless step

    update!(current_step_id: step_id)

    complete! if step.last_step?
    true
  end

  # 完了
  def complete!
    update!(
      completed: true,
      completed_at: Time.current
    )
  end

  # スキップ
  def skip!
    update!(
      skipped: true,
      completed_at: Time.current
    )
  end

  # リセット
  def reset!
    update!(
      current_step_id: nil,
      completed: false,
      skipped: false,
      started_at: nil,
      completed_at: nil,
      step_data: {}
    )
  end

  # 現在のステップを取得
  def current_step
    return nil if current_step_id.blank?

    TutorialStep.find_by(tutorial_type: tutorial_type, step_id: current_step_id)
  end

  # 全ステップを取得
  def steps
    TutorialStep.for_type(tutorial_type)
  end

  # 進捗率
  def progress_percentage
    return 0 if steps.empty?
    return 100 if completed?

    current = current_step
    return 0 if current.nil?

    ((current.position.to_f / steps.count) * 100).round
  end

  # ステータス
  def status
    return :completed if completed?
    return :skipped if skipped?
    return :not_started if started_at.nil?

    :in_progress
  end

  def status_label
    case status
    when :completed then I18n.t('models.tutorial_progress.completed')
    when :skipped then I18n.t('models.tutorial_progress.skipped')
    when :in_progress then I18n.t('models.tutorial_progress.in_progress')
    else I18n.t('models.tutorial_progress.not_started')
    end
  end

  # JSON出力
  def as_json_for_tutorial
    {
      id: id,
      tutorial_type: tutorial_type,
      current_step_id: current_step_id,
      current_step: current_step&.as_json_for_tutorial,
      completed: completed,
      skipped: skipped,
      started_at: started_at&.iso8601,
      completed_at: completed_at&.iso8601,
      progress_percentage: progress_percentage,
      status: status,
      status_label: status_label,
      total_steps: steps.count
    }
  end

  private

  def update_step_data
    return if current_step_id.blank?

    self.step_data = step_data.merge(
      current_step_id => {
        viewed_at: Time.current.iso8601
      }
    )
  end
end
