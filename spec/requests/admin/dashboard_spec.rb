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

      it "includes entry_stats with recent entries" do
        contest = create(:contest, :published, user: create(:user, :organizer, :confirmed))
        create(:entry, contest: contest, user: create(:user, :confirmed), created_at: 1.day.ago)

        get admin_dashboard_path
        expect(response).to have_http_status(:success)
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

  describe "PATCH /admin/dashboard/preferences" do
    before { sign_in admin }

    it "saves widget visibility settings" do
      patch preferences_admin_dashboard_path, params: {
        widget_visibility: { "stats" => "0", "charts" => "1" }
      }
      expect(response).to redirect_to(admin_dashboard_path)
      admin.reload
      expect(admin.widget_visible?("stats")).to be false
      expect(admin.widget_visible?("charts")).to be true
    end

    it "saves widget order" do
      custom_order = %w[recent_entries stats charts recent_users recent_contests]
      patch preferences_admin_dashboard_path, params: {
        widget_order: custom_order
      }
      expect(response).to redirect_to(admin_dashboard_path)
      expect(admin.reload.widget_order).to eq(custom_order)
    end
  end

  describe "GET /admin/dashboard with hidden widgets" do
    before { sign_in admin }

    it "hides widgets that are disabled" do
      admin.update_dashboard_settings("widget_visibility" => { "recent_users" => false })
      get admin_dashboard_path
      expect(response).to have_http_status(:success)
      expect(response.body).not_to include("recent-users-widget")
    end
  end
end
