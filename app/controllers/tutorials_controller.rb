# frozen_string_literal: true

class TutorialsController < ApplicationController
  before_action :authenticate_user!
  before_action :validate_tutorial_type, only: [ :show, :start, :update, :skip, :reset ]

  # GET /tutorials/status
  # 全チュートリアルの進捗状況を取得
  def status
    progresses = current_user.tutorial_progresses.index_by(&:tutorial_type)
    available_types = TutorialStep.types_for_role(current_user.role)

    render json: {
      progresses: progresses.transform_values { |p| progress_json(p) },
      available_types: available_types,
      should_show_onboarding: should_show_onboarding?,
      onboarding_type: onboarding_tutorial_type,
      feature_level: current_user.feature_level,
      available_features: current_user.available_features
    }
  end

  # GET /tutorials/:tutorial_type
  # 特定のチュートリアルの詳細を取得
  def show
    steps = TutorialStep.for_type(params[:tutorial_type])
    progress = current_user.tutorial_progresses.find_by(tutorial_type: params[:tutorial_type])

    render json: {
      steps: steps.map(&:as_json_for_tutorial),
      progress: progress_json(progress),
      settings: tutorial_settings
    }
  end

  # POST /tutorials/:tutorial_type/start
  # チュートリアルを開始
  def start
    service = TutorialProgressService.new(current_user)
    progress = service.start(params[:tutorial_type])

    render json: { progress: progress_json(progress) }
  end

  # PATCH /tutorials/:tutorial_type
  # 次のステップへ進む / 特定のステップを完了
  def update
    service = TutorialProgressService.new(current_user)
    result = service.complete_step(
      params[:tutorial_type],
      params[:step_id],
      params[:duration_ms]
    )

    if result
      render json: result
    else
      render json: { error: "Progress not found" }, status: :not_found
    end
  end

  # POST /tutorials/:tutorial_type/skip
  # チュートリアルをスキップ
  def skip
    service = TutorialProgressService.new(current_user)

    result = if params[:skip_all]
               { progress: service.skip_all(params[:tutorial_type]) }
    elsif params[:step_id].present?
               service.skip_step(params[:tutorial_type], params[:step_id])
    else
               { progress: service.skip_all(params[:tutorial_type]) }
    end

    render json: result
  end

  # POST /tutorials/:tutorial_type/reset
  # チュートリアルをリセット
  def reset
    service = TutorialProgressService.new(current_user)
    service.reset(params[:tutorial_type])

    render json: {
      success: true,
      message: t('tutorials.api.reset_success')
    }
  end

  # PATCH /tutorials/settings
  # チュートリアル設定を更新
  def update_settings
    permitted_settings = params.permit(:show_tutorials, :show_context_help, :reduced_motion)

    if current_user.update_tutorial_settings(permitted_settings.to_h)
      render json: {
        success: true,
        settings: current_user.tutorial_settings,
        message: t('tutorials.api.settings_updated')
      }
    else
      render json: {
        success: false,
        error: t('tutorials.api.settings_update_failed')
      }, status: :unprocessable_entity
    end
  end

  private

  def progress_json(progress)
    return nil unless progress

    {
      tutorial_type: progress.tutorial_type,
      current_step_id: progress.current_step_id,
      completed: progress.completed,
      skipped: progress.skipped,
      started_at: progress.started_at,
      completed_at: progress.completed_at,
      completion_method: progress.completion_method
    }
  end

  def tutorial_settings
    settings = current_user.tutorial_settings || {}
    {
      show_tutorials: settings.fetch("show_tutorials", true),
      show_context_help: settings.fetch("show_context_help", true),
      reduced_motion: settings.fetch("reduced_motion", false)
    }
  end

  def should_show_onboarding?
    type = onboarding_tutorial_type
    return false unless type

    progress = current_user.tutorial_progresses.find_by(tutorial_type: type)
    progress.nil? || (!progress.completed && !progress.skipped)
  end

  def onboarding_tutorial_type
    TutorialStep.onboarding_type_for_role(current_user.role)
  end

  def validate_tutorial_type
    unless TutorialStep::TUTORIAL_TYPES.values.include?(params[:tutorial_type])
      render json: {
        success: false,
        error: t('tutorials.api.invalid_tutorial_type')
      }, status: :bad_request
    end
  end
end
