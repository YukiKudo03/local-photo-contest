# frozen_string_literal: true

module My
  class ApiTokensController < ApplicationController
    before_action :authenticate_user!

    def index
      @api_tokens = current_user.api_tokens.where(revoked_at: nil).order(created_at: :desc)
    end

    def create
      @api_token = current_user.api_tokens.build(api_token_params)

      if @api_token.save
        flash[:api_token_value] = @api_token.token
        redirect_to my_api_tokens_path, notice: I18n.t("my.api_tokens.created")
      else
        @api_tokens = current_user.api_tokens.where(revoked_at: nil).order(created_at: :desc)
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      @api_token = current_user.api_tokens.find_by(id: params[:id])

      if @api_token
        @api_token.revoke!
        redirect_to my_api_tokens_path, notice: I18n.t("my.api_tokens.revoked")
      else
        redirect_to my_api_tokens_path, alert: I18n.t("my.api_tokens.not_found")
      end
    end

    private

    def api_token_params
      params.require(:api_token).permit(:name)
    end
  end
end
