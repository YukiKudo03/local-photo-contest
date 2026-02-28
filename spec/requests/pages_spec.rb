# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /privacy-policy" do
    it "returns success" do
      get "/privacy-policy"
      expect(response).to have_http_status(:success)
    end

    it "renders privacy policy content" do
      get "/privacy-policy"
      expect(response.body).to include("プライバシーポリシー")
    end

    it "does not require authentication" do
      get "/privacy-policy"
      expect(response).not_to redirect_to(new_user_session_path)
    end

    context "with English locale" do
      it "renders English content" do
        get "/privacy-policy", headers: { "Accept-Language" => "en" }
        expect(response.body).to include("Privacy Policy")
      end
    end
  end

  describe "GET /terms-of-service" do
    it "returns success" do
      get "/terms-of-service"
      expect(response).to have_http_status(:success)
    end

    it "does not require authentication" do
      get "/terms-of-service"
      expect(response).not_to redirect_to(new_user_session_path)
    end

    context "when TermsOfService.current exists" do
      let!(:terms) { create(:terms_of_service) }

      it "renders the current terms content" do
        get "/terms-of-service"
        expect(response.body).to include(terms.content)
      end
    end

    context "when TermsOfService.current is nil" do
      it "renders placeholder text" do
        get "/terms-of-service"
        expect(response.body).to include("利用規約は現在準備中です")
      end
    end
  end
end
