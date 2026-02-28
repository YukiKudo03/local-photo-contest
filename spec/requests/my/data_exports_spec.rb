# frozen_string_literal: true

require "rails_helper"

RSpec.describe "My::DataExports", type: :request do
  let(:user) { create(:user, :confirmed) }

  before { sign_in user }

  describe "POST /my/data_exports" do
    it "creates a data export request" do
      expect {
        post my_data_exports_path
      }.to change(DataExportRequest, :count).by(1)
    end

    it "enqueues the export job" do
      expect {
        post my_data_exports_path
      }.to have_enqueued_job(UserDataExportJob)
    end

    it "redirects to the show page" do
      post my_data_exports_path
      expect(response).to redirect_to(my_data_export_path(DataExportRequest.last))
    end

    context "when rate limited" do
      before { create(:data_export_request, user: user, requested_at: 1.hour.ago) }

      it "does not create a new request" do
        expect {
          post my_data_exports_path
        }.not_to change(DataExportRequest, :count)
      end

      it "redirects with an alert" do
        post my_data_exports_path
        expect(response).to redirect_to(my_profile_path)
        follow_redirect!
        expect(response.body).to include(I18n.t("gdpr.data_export.rate_limited"))
      end
    end

    context "when not signed in" do
      before { sign_out user }

      it "redirects to login" do
        post my_data_exports_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /my/data_exports/:id" do
    let(:export_request) { create(:data_export_request, user: user) }

    it "returns success" do
      get my_data_export_path(export_request)
      expect(response).to have_http_status(:success)
    end

    it "shows the export status" do
      get my_data_export_path(export_request)
      expect(response.body).to include(I18n.t("gdpr.data_export.status.pending"))
    end
  end

  describe "GET /my/data_exports/:id/download" do
    let(:export_request) { create(:data_export_request, :completed, user: user) }

    context "when export is completed and not expired" do
      before do
        export_request.file.attach(
          io: StringIO.new("test"),
          filename: "export.zip",
          content_type: "application/zip"
        )
      end

      it "redirects to the file download" do
        get download_my_data_export_path(export_request)
        expect(response).to have_http_status(:redirect)
      end
    end

    context "when export is expired" do
      let(:export_request) { create(:data_export_request, :expired, user: user) }

      it "redirects with an alert" do
        get download_my_data_export_path(export_request)
        expect(response).to redirect_to(my_profile_path)
      end
    end
  end
end
