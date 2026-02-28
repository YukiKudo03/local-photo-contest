# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::Base
      skip_forgery_protection

      before_action :authenticate_api_token!
      before_action :set_api_locale

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable
      rescue_from ActionController::ParameterMissing, with: :render_bad_request

      private

      def authenticate_api_token!
        token_string = extract_bearer_token
        unless token_string
          render_unauthorized and return
        end

        @current_api_token = ApiToken.active.find_by(token: token_string)
        unless @current_api_token
          render_unauthorized and return
        end

        @current_api_token.touch_last_used!
        @current_user = @current_api_token.user
      end

      def current_user
        @current_user
      end

      def current_api_token
        @current_api_token
      end

      def extract_bearer_token
        header = request.headers["Authorization"]
        return nil unless header&.start_with?("Bearer ")
        header.split(" ", 2).last
      end

      def require_scope!(scope)
        return if current_api_token.scope?(scope)
        render json: {
          error: { code: "forbidden", message: I18n.t("api.errors.insufficient_scope") }
        }, status: :forbidden
      end

      def set_api_locale
        locale = request.headers["Accept-Language"]&.scan(/[a-z]{2}/)&.first
        I18n.locale = I18n.available_locales.map(&:to_s).include?(locale) ? locale : I18n.default_locale
      end

      def paginate(scope)
        page_num = (params[:page] || 1).to_i
        per_num = [ (params[:per_page] || 25).to_i, 100 ].min

        @collection = scope.page(page_num).per(per_num)
        set_pagination_headers(@collection)
        @collection
      end

      def set_pagination_headers(collection)
        response.headers["X-Total-Count"] = collection.total_count.to_s
        response.headers["X-Total-Pages"] = collection.total_pages.to_s
        response.headers["X-Current-Page"] = collection.current_page.to_s
        response.headers["X-Per-Page"] = collection.limit_value.to_s
      end

      def render_unauthorized
        render json: {
          error: { code: "unauthorized", message: I18n.t("api.errors.unauthorized") }
        }, status: :unauthorized
      end

      def render_not_found
        render json: {
          error: { code: "not_found", message: I18n.t("api.errors.not_found") }
        }, status: :not_found
      end

      def render_unprocessable(exception)
        render json: {
          error: {
            code: "unprocessable_entity",
            message: exception.record.errors.full_messages.join(", "),
            details: exception.record.errors.messages
          }
        }, status: :unprocessable_entity
      end

      def render_bad_request(exception)
        render json: {
          error: { code: "bad_request", message: exception.message }
        }, status: :bad_request
      end

      def render_forbidden
        render json: {
          error: { code: "forbidden", message: I18n.t("api.errors.forbidden") }
        }, status: :forbidden
      end
    end
  end
end
