# frozen_string_literal: true

module My
  class TutorialSettingsController < ApplicationController
    before_action :authenticate_user!

    def show
      @tutorial_progresses = tutorial_types_with_progress
    end

    def update
      if current_user.update_tutorial_settings(tutorial_settings_params)
        redirect_to my_tutorial_settings_path, notice: t('flash.tutorial_settings.updated')
      else
        @tutorial_progresses = tutorial_types_with_progress
        flash.now[:alert] = t('flash.tutorial_settings.update_failed')
        render :show, status: :unprocessable_entity
      end
    end

    private

    def tutorial_settings_params
      params.require(:tutorial_settings).permit(:show_tutorials, :show_context_help, :reduced_motion)
        .transform_values { |v| v == "1" || v == "true" || v == true }
    end

    def tutorial_types_with_progress
      available_types = available_tutorial_types_for_user
      available_types.map do |type|
        progress = current_user.tutorial_progress_for(type)
        {
          type: type,
          label: tutorial_type_label(type),
          description: tutorial_type_description(type),
          progress: progress,
          step_count: TutorialStep.for_type(type).count
        }
      end
    end

    def available_tutorial_types_for_user
      types = []

      # オンボーディング（ロールに応じて）
      types << current_user.onboarding_tutorial_type

      # 運営者向け機能
      if current_user.organizer? || current_user.admin?
        types += %w[contest_creation area_management]
      end

      # 参加者向け機能
      types += %w[photo_submission voting]

      # 審査員向け
      types << "judge_onboarding" if current_user.judge?

      types.compact.uniq
    end

    def tutorial_type_label(type)
      t("tutorials.types.#{type}.label", default: type)
    end

    def tutorial_type_description(type)
      t("tutorials.types.#{type}.description", default: "")
    end
  end
end
