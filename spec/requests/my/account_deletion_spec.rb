# frozen_string_literal: true

require "rails_helper"

RSpec.describe "My::AccountDeletions", type: :request do
  let(:user) { create(:user, :confirmed, password: "password123") }

  before { sign_in user }

  describe "GET /my/account_deletion/new" do
    it "returns success" do
      get new_my_account_deletion_path
      expect(response).to have_http_status(:success)
    end

    context "when deletion already requested" do
      before { user.update!(deletion_requested_at: Time.current, deletion_scheduled_at: 30.days.from_now) }

      it "shows cancellation option" do
        get new_my_account_deletion_path
        expect(response.body).to include(I18n.t("gdpr.account_deletion.cancel_button"))
      end
    end

    context "when not signed in" do
      before { sign_out user }

      it "redirects to login" do
        get new_my_account_deletion_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /my/account_deletion" do
    it "requests account deletion with correct password" do
      post my_account_deletion_path, params: { password: "password123" }
      user.reload
      expect(user.deletion_requested_at).to be_present
      expect(user.deletion_scheduled_at).to be_present
    end

    it "sends a deletion requested email" do
      expect {
        post my_account_deletion_path, params: { password: "password123" }
      }.to have_enqueued_mail(AccountDeletionMailer, :deletion_requested)
    end

    it "creates an audit log entry" do
      expect {
        post my_account_deletion_path, params: { password: "password123" }
      }.to change(AuditLog, :count).by(1)
    end

    it "redirects with error on wrong password" do
      post my_account_deletion_path, params: { password: "wrong" }
      user.reload
      expect(user.deletion_requested_at).to be_nil
    end
  end

  describe "DELETE /my/account_deletion" do
    before { user.update!(deletion_requested_at: Time.current, deletion_scheduled_at: 30.days.from_now) }

    it "cancels the deletion request" do
      delete my_account_deletion_path
      user.reload
      expect(user.deletion_requested_at).to be_nil
      expect(user.deletion_scheduled_at).to be_nil
    end

    it "sends a cancellation email" do
      expect {
        delete my_account_deletion_path
      }.to have_enqueued_mail(AccountDeletionMailer, :deletion_cancelled)
    end

    it "creates an audit log entry" do
      expect {
        delete my_account_deletion_path
      }.to change(AuditLog, :count).by(1)
    end
  end
end
