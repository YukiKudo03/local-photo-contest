# frozen_string_literal: true

module Api
  module V1
    class MeController < BaseController
      def show
        render json: {
          id: current_user.id,
          email: current_user.email,
          name: current_user.display_name,
          role: current_user.role,
          created_at: current_user.created_at.iso8601
        }
      end
    end
  end
end
