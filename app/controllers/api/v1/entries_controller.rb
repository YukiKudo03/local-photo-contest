# frozen_string_literal: true

module Api
  module V1
    class EntriesController < BaseController
      def index
        contest = Contest.active
                        .where(status: [ :published, :finished ])
                        .find(params[:contest_id])

        entries = contest.entries.visible.recent
        @entries = paginate(entries)
      end

      def show
        @entry = Entry.visible.find(params[:id])
        @current_user = current_user
      end

      def create
        require_scope!("write")
        return if performed?

        contest = Contest.active
                        .where(status: [ :published ])
                        .find(params[:contest_id])

        unless contest.accepting_entries?
          render_not_found and return
        end

        @entry = contest.entries.build(entry_params)
        @entry.user = current_user

        if @entry.save
          render :show, status: :created
        else
          render json: {
            error: {
              code: "unprocessable_entity",
              message: @entry.errors.full_messages.join(", "),
              details: @entry.errors.messages
            }
          }, status: :unprocessable_entity
        end
      end

      private

      def entry_params
        params.require(:entry).permit(:title, :description, :location, :photo, :spot_id)
      end
    end
  end
end
