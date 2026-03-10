require "rails_helper"

RSpec.describe "Admin::AuditLogs", type: :request do
  let!(:terms) { create(:terms_of_service, :current) }
  let!(:admin) { create(:user, :admin, :confirmed) }
  let!(:participant) { create(:user, :confirmed) }

  before do
    create(:terms_acceptance, user: admin, terms_of_service: terms)
  end

  describe "GET /admin/audit_logs" do
    context "when logged in as admin" do
      before { sign_in admin }

      it "returns success" do
        get admin_audit_logs_path

        expect(response).to have_http_status(:success)
      end

      context "with audit log records" do
        let!(:log1) { AuditLog.log(action: "login", user: admin) }
        let!(:log2) { AuditLog.log(action: "logout", user: participant) }

        it "displays audit logs" do
          get admin_audit_logs_path

          expect(response).to have_http_status(:success)
        end

        it "filters by action_type" do
          get admin_audit_logs_path, params: { action_type: "login" }

          expect(response).to have_http_status(:success)
        end

        it "filters by user_id" do
          get admin_audit_logs_path, params: { user_id: admin.id }

          expect(response).to have_http_status(:success)
        end

        it "filters by date range" do
          get admin_audit_logs_path, params: {
            from: 1.day.ago.to_date.to_s,
            to: Date.current.to_s
          }

          expect(response).to have_http_status(:success)
        end

        it "combines multiple filters" do
          get admin_audit_logs_path, params: {
            action_type: "login",
            user_id: admin.id,
            from: 1.day.ago.to_date.to_s,
            to: Date.current.to_s
          }

          expect(response).to have_http_status(:success)
        end
      end
    end

    context "when logged in as non-admin" do
      before { sign_in participant }

      it "redirects to root" do
        get admin_audit_logs_path

        expect(response).to redirect_to(root_path)
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        get admin_audit_logs_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /admin/audit_logs/:id" do
    context "when logged in as admin" do
      before { sign_in admin }

      it "returns success" do
        log = AuditLog.log(action: "login", user: admin)

        get admin_audit_log_path(log)

        expect(response).to have_http_status(:success)
      end
    end

    context "when logged in as non-admin" do
      before { sign_in participant }

      it "redirects to root" do
        log = AuditLog.log(action: "login", user: admin)

        get admin_audit_log_path(log)

        expect(response).to redirect_to(root_path)
      end
    end
  end
end
