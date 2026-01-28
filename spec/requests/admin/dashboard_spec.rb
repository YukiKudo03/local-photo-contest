# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  let!(:terms) { create(:terms_of_service, :current) }
  let!(:admin) { create(:user, :admin, :confirmed) }
  let!(:organizer) { create(:user, :organizer, :confirmed) }
  let!(:participant) { create(:user, :confirmed) }

  before do
    create(:terms_acceptance, user: admin, terms_of_service: terms)
    create(:terms_acceptance, user: organizer, terms_of_service: terms)
  end

  describe "GET /admin/dashboard" do
    context "when logged in as admin" do
      before { sign_in admin }

      it "returns success" do
        get admin_dashboard_path
        expect(response).to have_http_status(:success)
      end

      it "displays dashboard statistics" do
        get admin_dashboard_path
        expect(response.body).to include("管理者ダッシュボード")
        expect(response.body).to include("総ユーザー数")
        expect(response.body).to include("総コンテスト数")
      end
    end

    context "when logged in as organizer" do
      before { sign_in organizer }

      it "redirects to root with alert" do
        get admin_dashboard_path
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("管理者権限が必要です")
      end
    end

    context "when logged in as participant" do
      before { sign_in participant }

      it "redirects to root with alert" do
        get admin_dashboard_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        get admin_dashboard_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
