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

    it "renders edit on invalid update" do
      allow_any_instance_of(User).to receive(:update).and_return(false)
      patch admin_user_path(participant), params: { user: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
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

  describe "POST /admin/users/bulk_suspend" do
    it "suspends multiple users" do
      post bulk_suspend_admin_users_path, params: { user_ids: [ participant.id, organizer.id ] }
      expect(participant.reload.access_locked?).to be true
      expect(organizer.reload.access_locked?).to be true
    end

    it "redirects with count notice" do
      post bulk_suspend_admin_users_path, params: { user_ids: [ participant.id ] }
      expect(response).to redirect_to(admin_users_path)
    end

    it "creates audit log entries" do
      expect {
        post bulk_suspend_admin_users_path, params: { user_ids: [ participant.id, organizer.id ] }
      }.to change(AuditLog, :count).by(2)
    end

    it "skips admin users" do
      other_admin = create(:user, :admin, :confirmed)
      post bulk_suspend_admin_users_path, params: { user_ids: [ other_admin.id, participant.id ] }
      expect(other_admin.reload.access_locked?).to be false
      expect(participant.reload.access_locked?).to be true
    end

    it "redirects with alert when no users selected" do
      post bulk_suspend_admin_users_path, params: { user_ids: [] }
      expect(response).to redirect_to(admin_users_path)
    end

    it "redirects with no_users_selected alert when user_ids is nil" do
      post bulk_suspend_admin_users_path
      expect(response).to redirect_to(admin_users_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "POST /admin/users/bulk_unsuspend" do
    before do
      participant.update!(locked_at: Time.current, failed_attempts: 5)
      organizer.update!(locked_at: Time.current, failed_attempts: 3)
    end

    it "unsuspends multiple users" do
      post bulk_unsuspend_admin_users_path, params: { user_ids: [ participant.id, organizer.id ] }
      expect(participant.reload.access_locked?).to be false
      expect(organizer.reload.access_locked?).to be false
    end

    it "resets failed_attempts" do
      post bulk_unsuspend_admin_users_path, params: { user_ids: [ participant.id ] }
      expect(participant.reload.failed_attempts).to eq(0)
    end

    it "creates audit log entries" do
      expect {
        post bulk_unsuspend_admin_users_path, params: { user_ids: [ participant.id, organizer.id ] }
      }.to change(AuditLog, :count).by(2)
    end

    it "redirects when no users selected" do
      post bulk_unsuspend_admin_users_path, params: { user_ids: [] }
      expect(response).to redirect_to(admin_users_path)
    end

    it "redirects with no_users_selected alert when user_ids is nil" do
      post bulk_unsuspend_admin_users_path
      expect(response).to redirect_to(admin_users_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "POST /admin/users/bulk_change_role" do
    it "changes role for multiple users" do
      post bulk_change_role_admin_users_path, params: { user_ids: [ participant.id ], role: "organizer" }
      expect(participant.reload.role).to eq("organizer")
    end

    it "rejects invalid role" do
      post bulk_change_role_admin_users_path, params: { user_ids: [ participant.id ], role: "superadmin" }
      expect(response).to redirect_to(admin_users_path)
      expect(participant.reload.role).to eq("participant")
    end

    it "creates audit log with role details" do
      post bulk_change_role_admin_users_path, params: { user_ids: [ participant.id ], role: "organizer" }
      log = AuditLog.last
      expect(log.action).to eq("role_change")
      expect(log.details).to include("new_role" => "organizer")
    end

    it "redirects when no users selected" do
      post bulk_change_role_admin_users_path, params: { user_ids: [], role: "organizer" }
      expect(response).to redirect_to(admin_users_path)
    end

    it "redirects with no_users_selected alert when user_ids is nil with valid role" do
      post bulk_change_role_admin_users_path, params: { role: "organizer" }
      expect(response).to redirect_to(admin_users_path)
      expect(flash[:alert]).to be_present
    end
  end
end
