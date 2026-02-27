# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_admin!

    layout "admin"

    private

    def ensure_admin!
      return if current_user.admin?

      flash[:alert] = t('flash.admin.admin_required')
      redirect_to root_path
    end
  end
end
