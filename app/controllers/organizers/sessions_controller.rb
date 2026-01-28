# frozen_string_literal: true

module Organizers
  class SessionsController < Devise::SessionsController
    protected

    def after_sign_in_path_for(resource)
      organizers_dashboard_path
    end

    def after_sign_out_path_for(resource_or_scope)
      root_path
    end
  end
end
