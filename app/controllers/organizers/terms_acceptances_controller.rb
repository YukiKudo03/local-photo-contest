# frozen_string_literal: true

module Organizers
  class TermsAcceptancesController < BaseController
    # Skip terms acceptance check for this controller
    skip_before_action :require_terms_acceptance!

    def new
      @terms = current_terms
      redirect_to organizers_dashboard_path if @terms.nil? || accepted_current_terms?
    end

    def create
      if current_terms.nil?
        redirect_to organizers_dashboard_path
        return
      end

      current_user.accept_terms!(current_terms, request.remote_ip)
      redirect_to organizers_dashboard_path, notice: "利用規約に同意しました。"
    end
  end
end
