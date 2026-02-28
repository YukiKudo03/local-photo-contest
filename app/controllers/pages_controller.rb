# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def privacy_policy; end

  def terms_of_service
    @terms = TermsOfService.current
  end
end
