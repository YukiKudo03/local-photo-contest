# frozen_string_literal: true

module My
  class JudgeEvaluationsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_contest_judge
    before_action :set_entry, only: [ :show, :create, :update ]
    before_action :check_can_evaluate, only: [ :create, :update ]

    def index
      @entries = @contest.entries.includes(:user, :judge_evaluations, photo_attachment: :blob)
                         .order(created_at: :asc)
      @criteria = @contest.evaluation_criteria.ordered
    end

    def show
      @criteria = @contest.evaluation_criteria.ordered
      @evaluations = @contest_judge.judge_evaluations.where(entry: @entry).index_by(&:evaluation_criterion_id)
      @comment = @contest_judge.judge_comments.find_by(entry: @entry) || @contest_judge.judge_comments.build(entry: @entry)
    end

    def create
      ActiveRecord::Base.transaction do
        save_evaluations
        save_comment
      end

      redirect_to my_judge_assignment_evaluation_path(@contest_judge, @entry),
                  notice: t('flash.judge_evaluations.created')
    rescue ActiveRecord::RecordInvalid => e
      @criteria = @contest.evaluation_criteria.ordered
      @evaluations = @contest_judge.judge_evaluations.where(entry: @entry).index_by(&:evaluation_criterion_id)
      @comment = @contest_judge.judge_comments.find_by(entry: @entry) || @contest_judge.judge_comments.build(entry: @entry)
      flash.now[:alert] = e.record.errors.full_messages.join(", ")
      render :show, status: :unprocessable_entity
    end

    def update
      ActiveRecord::Base.transaction do
        save_evaluations
        save_comment
      end

      redirect_to my_judge_assignment_evaluation_path(@contest_judge, @entry),
                  notice: t('flash.judge_evaluations.updated')
    rescue ActiveRecord::RecordInvalid => e
      @criteria = @contest.evaluation_criteria.ordered
      @evaluations = @contest_judge.judge_evaluations.where(entry: @entry).index_by(&:evaluation_criterion_id)
      @comment = @contest_judge.judge_comments.find_by(entry: @entry) || @contest_judge.judge_comments.build(entry: @entry)
      flash.now[:alert] = e.record.errors.full_messages.join(", ")
      render :show, status: :unprocessable_entity
    end

    private

    def set_contest_judge
      @contest_judge = current_user.contest_judges.find(params[:judge_assignment_id])
      @contest = @contest_judge.contest
    end

    def set_entry
      entry_id = params[:id] || params[:entry_id]
      @entry = @contest.entries.find(entry_id)
    end

    def check_can_evaluate
      return unless @entry.user == current_user

      redirect_to my_judge_assignment_path(@contest_judge),
                  alert: t('flash.judge_evaluations.cannot_evaluate_own')
    end

    def save_evaluations
      return unless params[:evaluations].present?

      params[:evaluations].each do |criterion_id, score|
        next if score.blank?

        evaluation = @contest_judge.judge_evaluations.find_or_initialize_by(
          entry: @entry,
          evaluation_criterion_id: criterion_id
        )
        evaluation.score = score
        evaluation.save!
      end
    end

    def save_comment
      return unless params[:comment].present?

      comment = @contest_judge.judge_comments.find_or_initialize_by(entry: @entry)
      comment.comment = params[:comment]
      comment.save!
    end
  end
end
