# frozen_string_literal: true

class TutorialProgressService
  def initialize(user)
    @user = user
  end

  # チュートリアル開始
  def start(tutorial_type)
    progress = find_or_initialize_progress(tutorial_type)

    if progress.new_record?
      progress.started_at = Time.current
      progress.current_step_id = first_step_id(tutorial_type)
      progress.save!
    end

    progress
  end

  # ステップ完了
  def complete_step(tutorial_type, step_id, duration_ms = nil)
    progress = find_progress(tutorial_type)
    return nil unless progress

    # 滞在時間を記録
    if duration_ms
      progress.step_times ||= {}
      progress.step_times[step_id] = duration_ms
    end

    step = TutorialStep.find_by(tutorial_type: tutorial_type, step_id: step_id)
    next_step = step&.next_step

    if next_step
      progress.current_step_id = next_step.step_id
      progress.save!
    else
      complete_tutorial(progress, "completed")
    end

    # フィードバックを返す
    {
      progress: progress,
      feedback: step&.feedback_config,
      next_step: next_step&.as_json_for_tutorial,
      completed: progress.completed?
    }
  end

  # スキップ
  def skip_step(tutorial_type, step_id)
    progress = find_progress(tutorial_type)
    return nil unless progress

    progress.skipped_steps ||= []
    progress.skipped_steps << step_id
    step = TutorialStep.find_by(tutorial_type: tutorial_type, step_id: step_id)
    next_step = step&.next_step

    if next_step
      progress.current_step_id = next_step.step_id
      progress.save!
    else
      complete_tutorial(progress, "skipped_all")
    end

    { progress: progress, next_step: next_step&.as_json_for_tutorial }
  end

  # 全スキップ
  def skip_all(tutorial_type)
    progress = find_or_initialize_progress(tutorial_type)
    complete_tutorial(progress, "skipped_all")
    progress
  end

  # リセット
  def reset(tutorial_type)
    progress = find_progress(tutorial_type)
    return nil unless progress

    progress.destroy
    nil
  end

  private

  def find_or_initialize_progress(tutorial_type)
    @user.tutorial_progresses.find_or_initialize_by(tutorial_type: tutorial_type)
  end

  def find_progress(tutorial_type)
    @user.tutorial_progresses.find_by(tutorial_type: tutorial_type)
  end

  def first_step_id(tutorial_type)
    TutorialStep.for_type(tutorial_type).first&.step_id
  end

  def complete_tutorial(progress, method)
    progress.completed = true
    progress.completed_at = Time.current
    progress.completion_method = method
    progress.save!

    # マイルストーン達成
    MilestoneService.new(@user).check_tutorial_milestone(progress.tutorial_type)
  end
end
