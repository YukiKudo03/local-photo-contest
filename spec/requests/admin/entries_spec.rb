# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Entries", type: :request do
  let!(:terms) { create(:terms_of_service, :current) }
  let!(:admin) { create(:user, :admin, :confirmed) }
  let!(:contest) { create(:contest, :accepting_entries) }
  let!(:entry1) { create(:entry, contest: contest, moderation_status: :moderation_requires_review) }
  let!(:entry2) { create(:entry, contest: contest, moderation_status: :moderation_hidden) }
  let!(:approved_entry) { create(:entry, contest: contest, moderation_status: :moderation_approved, title: "承認済みユニークタイトル") }

  before do
    create(:terms_acceptance, user: admin, terms_of_service: terms)
    sign_in admin
  end

  describe "GET /admin/entries" do
    it "returns success" do
      get admin_entries_path
      expect(response).to have_http_status(:success)
    end

    it "shows entries needing moderation review" do
      get admin_entries_path
      expect(response.body).to include(entry1.title)
      expect(response.body).to include(entry2.title)
    end

    it "does not show approved entries" do
      get admin_entries_path
      expect(response.body).not_to include("承認済みユニークタイトル")
    end
  end

  describe "POST /admin/entries/bulk_approve" do
    it "approves multiple entries" do
      post bulk_approve_admin_entries_path, params: { entry_ids: [ entry1.id, entry2.id ] }
      expect(entry1.reload.moderation_approved?).to be true
      expect(entry2.reload.moderation_approved?).to be true
    end

    it "redirects with count notice" do
      post bulk_approve_admin_entries_path, params: { entry_ids: [ entry1.id ] }
      expect(response).to redirect_to(admin_entries_path)
    end

    it "creates audit log entries" do
      expect {
        post bulk_approve_admin_entries_path, params: { entry_ids: [ entry1.id, entry2.id ] }
      }.to change(AuditLog, :count).by(2)
    end
  end

  describe "POST /admin/entries/bulk_reject" do
    it "rejects multiple entries" do
      post bulk_reject_admin_entries_path, params: { entry_ids: [ entry1.id ] }
      expect(entry1.reload.moderation_hidden?).to be true
    end

    it "creates audit log entries" do
      expect {
        post bulk_reject_admin_entries_path, params: { entry_ids: [ entry1.id ] }
      }.to change(AuditLog, :count).by(1)
    end
  end

  context "when not admin" do
    let!(:participant) { create(:user, :confirmed) }

    before do
      create(:terms_acceptance, user: participant, terms_of_service: terms)
      sign_in participant
    end

    it "redirects to root" do
      get admin_entries_path
      expect(response).to redirect_to(root_path)
    end
  end
end
