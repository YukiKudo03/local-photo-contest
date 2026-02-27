# frozen_string_literal: true

module Organizers
  class ConfirmationsController < Devise::ConfirmationsController
    protected

    def after_confirmation_path_for(resource_name, resource)
      flash[:notice] = t('flash.confirmations.confirmed')
      new_user_session_path
    end
  end
end
