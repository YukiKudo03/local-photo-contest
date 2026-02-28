# frozen_string_literal: true

module Api
  module V1
    class ContestsController < BaseController
      def index
        contests = Contest.active
                         .where(status: [ :published, :finished ])
                         .recent

        @contests = paginate(contests)
      end

      def show
        @contest = Contest.active
                         .where(status: [ :published, :finished ])
                         .find(params[:id])
      end
    end
  end
end
