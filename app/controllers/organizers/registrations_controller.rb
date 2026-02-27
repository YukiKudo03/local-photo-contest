# frozen_string_literal: true

module Organizers
  class RegistrationsController < Devise::RegistrationsController
    protected

    def after_inactive_sign_up_path_for(resource)
      flash[:notice] = t('flash.registrations.confirmation_sent')
      root_path
    end
  end
end
