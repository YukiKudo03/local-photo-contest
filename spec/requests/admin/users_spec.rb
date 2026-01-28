# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let!(:terms) { create(:terms_of_service, :current) }
  let!(:admin) { create(:user, :admin, :confirmed) }
  let!(:organizer) { create(:user, :organizer, :confirmed) }
  let!(:participant) { create(:user, :confirmed) }

  before do
    create(:terms_acceptance, user: admin, terms_of_service: terms)
    create(:terms_acceptance, user: organizer, terms_of_service: terms)
    create(:terms_acceptance, user: participant, terms_of_service: terms)
    sign_in admin
  end

  describe "GET /admin/users" do
    it "returns success" do
      get admin_users_path
      expect(response).to have_http_status(:success)
    end

    it "displays user list" do
      get admin_users_path
      expect(response.body).to include("ユーザー管理")
      expect(response.body).to include(admin.email)
      expect(response.body).to include(organizer.email)
    end

    context "with search query" do
      it "filters users by email" do
        get admin_users_path, params: { q: organizer.email }
        expect(response.body).to include(organizer.email)
      end
    end

    context "with role filter" do
      it "filters users by role" do
        get admin_users_path, params: { role: "organizer" }
        expect(response.body).to include(organizer.email)
      end
    end
  end

  describe "GET /admin/users/:id" do
    it "returns success" do
      get admin_user_path(participant)
      expect(response).to have_http_status(:success)
    end

    it "displays user details" do
      get admin_user_path(participant)
      expect(response.body).to include(participant.email)
      expect(response.body).to include("ユーザー情報")
    end
  end

  describe "PATCH /admin/users/:id" do
    it "updates user" do
      patch admin_user_path(participant), params: { user: { name: "Updated Name" } }
      expect(response).to redirect_to(admin_user_path(participant))
      expect(participant.reload.name).to eq("Updated Name")
    end
  end

  describe "PATCH /admin/users/:id/suspend" do
    it "suspends user account" do
      patch suspend_admin_user_path(participant)
      expect(response).to redirect_to(admin_user_path(participant))
      expect(participant.reload.access_locked?).to be true
    end
  end

  describe "PATCH /admin/users/:id/unsuspend" do
    before { participant.update!(locked_at: Time.current) }

    it "unsuspends user account" do
      patch unsuspend_admin_user_path(participant)
      expect(response).to redirect_to(admin_user_path(participant))
      expect(participant.reload.access_locked?).to be false
    end
  end

  describe "PATCH /admin/users/:id/change_role" do
    it "changes user role" do
      patch change_role_admin_user_path(participant), params: { role: "organizer" }
      expect(response).to redirect_to(admin_user_path(participant))
      expect(participant.reload.organizer?).to be true
    end

    it "rejects invalid role" do
      patch change_role_admin_user_path(participant), params: { role: "invalid" }
      expect(response).to redirect_to(admin_user_path(participant))
      follow_redirect!
      expect(response.body).to include("無効なロールです")
    end
  end

  describe "DELETE /admin/users/:id" do
    it "deletes user" do
      delete admin_user_path(participant)
      expect(response).to redirect_to(admin_users_path)
      expect(User.exists?(participant.id)).to be false
    end
  end
end
