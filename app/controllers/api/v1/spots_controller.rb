# frozen_string_literal: true

module Api
  module V1
    class SpotsController < BaseController
      def index
        contest = Contest.active
                        .where(status: [ :published, :finished ])
                        .find(params[:contest_id])

        @spots = contest.spots.certified_or_organizer.ordered
      end
    end
  end
end
