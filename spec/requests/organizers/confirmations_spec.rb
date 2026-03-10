require "rails_helper"

RSpec.describe "Organizers::Confirmations", type: :request do
  describe "GET /organizers/confirmation" do
    it "confirms the user and redirects to login page" do
      user = create(:user, :unconfirmed)
      raw_token = user.instance_variable_get(:@raw_confirmation_token) || user.send(:generate_confirmation_token!)
      raw_token = user.instance_variable_get(:@raw_confirmation_token)

      get user_confirmation_path(confirmation_token: raw_token)

      expect(response).to redirect_to(new_user_session_path)
      expect(user.reload.confirmed?).to be true
    end

    it "sets a flash notice on successful confirmation" do
      user = create(:user, :unconfirmed)
      user.send(:generate_confirmation_token!)
      raw_token = user.instance_variable_get(:@raw_confirmation_token)

      get user_confirmation_path(confirmation_token: raw_token)

      follow_redirect!
      expect(flash[:notice]).to be_present
    end

    it "does not confirm with an invalid token" do
      get user_confirmation_path(confirmation_token: "invalid_token")

      expect(response).to have_http_status(:success).or have_http_status(:unprocessable_entity)
    end
  end
end
