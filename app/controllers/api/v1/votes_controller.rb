# frozen_string_literal: true

module Api
  module V1
    class VotesController < BaseController
      before_action :set_entry

      def create
        require_scope!("write")
        return if performed?

        if @entry.user_id == current_user.id
          render json: {
            error: { code: "unprocessable_entity", message: I18n.t("api.errors.cannot_vote_own") }
          }, status: :unprocessable_entity
          return
        end

        vote = @entry.votes.build(user: current_user)
        if vote.save
          render json: { data: { id: vote.id, entry_id: @entry.id } }, status: :created
        else
          render json: {
            error: {
              code: "unprocessable_entity",
              message: vote.errors.full_messages.join(", ")
            }
          }, status: :unprocessable_entity
        end
      end

      def destroy
        require_scope!("write")
        return if performed?

        vote = @entry.votes.find_by!(user: current_user)
        vote.destroy!
        head :no_content
      end

      private

      def set_entry
        @entry = Entry.visible.find(params[:entry_id])
      end
    end
  end
end
