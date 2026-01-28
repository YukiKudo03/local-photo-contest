# frozen_string_literal: true

module Organizers
  class BaseController < ApplicationController
    include TermsAcceptable

    before_action :authenticate_user!
    before_action :require_organizer!
    before_action :require_terms_acceptance!

    private

    def require_organizer!
      return if current_user.organizer?

      respond_to do |format|
        format.html do
          flash[:alert] = "この操作を行う権限がありません。"
          redirect_to root_path, status: :forbidden
        end
        format.json { head :forbidden }
      end
    end
  end
end
