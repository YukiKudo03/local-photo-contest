# frozen_string_literal: true

module Api
  module V1
    class RankingsController < BaseController
      def index
        @contest = Contest.active
                         .where(status: [ :published, :finished ])
                         .find(params[:contest_id])

        unless @contest.results_announced?
          render_forbidden and return
        end

        @rankings = @contest.calculated_rankings
      end
    end
  end
end
