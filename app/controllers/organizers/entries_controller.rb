# frozen_string_literal: true

module Organizers
  class EntriesController < BaseController
    before_action :set_contest
    before_action :authorize_contest!
    before_action :set_entry, only: [ :show ]

    def index
      @entries = @contest.entries
                         .includes(:user, :spot, photo_attachment: :blob)
                         .recent
    end

    def show
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
