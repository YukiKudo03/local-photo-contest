# frozen_string_literal: true

module TermsAcceptable
  extend ActiveSupport::Concern

  included do
    helper_method :current_terms, :accepted_current_terms?
  end

  private

  def require_terms_acceptance!
    return if skip_terms_acceptance?
    return if current_terms.nil?
    return if accepted_current_terms?

    redirect_to new_organizers_terms_acceptance_path, alert: "利用規約への同意が必要です。"
  end

  def current_terms
    @current_terms ||= TermsOfService.current
  end

  def accepted_current_terms?
    return true if current_terms.nil?

    current_user.accepted_current_terms?
  end

  def skip_terms_acceptance?
    self.class.name == "Organizers::TermsAcceptancesController"
  end
end
