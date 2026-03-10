# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers::Passwords", type: :request do
  describe "after_resetting_password_path_for" do
    let!(:user) { create(:user, :organizer, :confirmed) }

    it "redirects to login after password reset" do
      token = user.send_reset_password_instructions

      put user_password_path, params: {
        user: {
          reset_password_token: token,
          password: "newpassword123",
          password_confirmation: "newpassword123"
        }
      }

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
