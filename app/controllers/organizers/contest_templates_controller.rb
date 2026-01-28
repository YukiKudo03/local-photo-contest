# frozen_string_literal: true

module Organizers
  class ContestTemplatesController < BaseController
    before_action :set_template, only: [:destroy]
    before_action :authorize_template!, only: [:destroy]
    before_action :set_contest, only: [:new, :create]

    def index
      @templates = current_user.contest_templates
                               .includes(:source_contest, :category, :area)
                               .recent
    end

    def new
      @template = current_user.contest_templates.build
    end

    def create
      @template = TemplateService.create_from_contest(
        @contest,
        name: template_params[:name],
        user: current_user
      )

      if @template.persisted?
        redirect_to organizers_contest_templates_path, notice: "テンプレートを保存しました。"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      @template.destroy
      redirect_to organizers_contest_templates_path, notice: "テンプレートを削除しました。"
    end

    private

    def set_template
      @template = ContestTemplate.find(params[:id])
    end

    def authorize_template!
      return if @template.owned_by?(current_user)

      redirect_to organizers_contest_templates_path, alert: "このテンプレートにアクセスする権限がありません。"
    end

    def set_contest
      @contest = current_user.contests.active.find(params[:contest_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to organizers_contests_path, alert: "コンテストが見つかりません。"
    end

    def template_params
      params.require(:contest_template).permit(:name)
    end
  end
end
