# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Locales", type: :request do
  let!(:terms) { create(:terms_of_service, :current) }
  let!(:user) { create(:user, :confirmed) }

  before do
    create(:terms_acceptance, user: user, terms_of_service: terms)
  end

  describe "PATCH /locale" do
    context "when authenticated" do
      before { sign_in user }

      it "updates session locale to ja" do
        patch locale_path, params: { locale: "ja" }

        expect(response).to have_http_status(:redirect)
      end

      it "updates session locale to en" do
        patch locale_path, params: { locale: "en" }

        expect(response).to have_http_status(:redirect)
      end

      it "updates the user locale preference" do
        patch locale_path, params: { locale: "en" }

        expect(user.reload.locale).to eq("en")
      end

      it "does not update user locale when same locale sent" do
        user.update!(locale: "ja")

        patch locale_path, params: { locale: "ja" }

        expect(response).to have_http_status(:redirect)
        expect(user.reload.locale).to eq("ja")
      end

      it "redirects back to the referring page" do
        patch locale_path, params: { locale: "ja" }, headers: { "HTTP_REFERER" => "/some/page" }

        expect(response).to redirect_to("/some/page")
      end
    end

    context "when not authenticated" do
      it "updates session locale without updating user" do
        patch locale_path, params: { locale: "en" }

        expect(response).to have_http_status(:redirect)
      end

      it "sets session locale" do
        patch locale_path, params: { locale: "ja" }

        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
