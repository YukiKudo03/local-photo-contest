# frozen_string_literal: true

module Organizers
  class ModerationController < BaseController
    before_action :set_contest
    before_action :authorize_contest!
    before_action :set_entry, only: [ :approve, :reject ]

    def index
      @entries = @contest.entries
                         .needs_moderation_review
                         .includes(:user, :moderation_result)
                         .recent
      @pending_count = @entries.count
    end

    def approve
      ActiveRecord::Base.transaction do
        @entry.moderation_approved!
        @entry.moderation_result&.mark_reviewed!(
          reviewer: current_user,
          approved: true,
          note: params[:note]
        )
      end

      respond_to do |format|
        format.html { redirect_to organizers_contest_moderation_index_path(@contest), notice: "エントリーを承認しました。" }
        format.turbo_stream
      end
    end

    def reject
      ActiveRecord::Base.transaction do
        @entry.moderation_hidden!
        @entry.moderation_result&.mark_reviewed!(
          reviewer: current_user,
          approved: false,
          note: params[:note]
        )
      end

      respond_to do |format|
        format.html { redirect_to organizers_contest_moderation_index_path(@contest), notice: "エントリーを却下しました。" }
        format.turbo_stream
      end
    end

    private

    def set_contest
      @contest = Contest.active.find(params[:contest_id])
    end

    def authorize_contest!
      return if @contest.owned_by?(current_user)

      redirect_to organizers_contests_path, alert: "この操作を行う権限がありません。"
    end

    def set_entry
      @entry = @contest.entries.find(params[:id])
    end
  end
end
