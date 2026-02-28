# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers::Statistics (Advanced)", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }

  before { sign_in organizer }

  describe "GET /organizers/contests/:contest_id/statistics/heatmap_data" do
    it "returns JSON heatmap data" do
      get heatmap_data_organizers_contest_statistics_path(contest), as: :json
      expect(response).to have_http_status(:success)

      data = JSON.parse(response.body)
      expect(data).to have_key("heatmap")
      expect(data["heatmap"].keys.size).to eq(7)
    end
  end

  describe "GET /organizers/contests/:contest_id/statistics/area_comparison" do
    it "returns area comparison page" do
      get area_comparison_organizers_contest_statistics_path(contest)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /organizers/contests/:contest_id/statistics/generate_report" do
    it "enqueues report generation and redirects" do
      expect {
        post generate_report_organizers_contest_statistics_path(contest)
      }.to have_enqueued_job(AnalyticsReportJob).with(contest.id)

      expect(response).to redirect_to(organizers_contest_statistics_path(contest))
    end
  end

  describe "GET /organizers/contests/:contest_id/statistics/download_report" do
    context "when report is attached" do
      before do
        contest.analytics_report_pdf.attach(
          io: StringIO.new("%PDF-fake"),
          filename: "report.pdf",
          content_type: "application/pdf"
        )
      end

      it "redirects to download" do
        get download_report_organizers_contest_statistics_path(contest)
        expect(response).to have_http_status(:redirect)
      end
    end

    context "when no report exists" do
      it "redirects with alert" do
        get download_report_organizers_contest_statistics_path(contest)
        expect(response).to redirect_to(organizers_contest_statistics_path(contest))
        expect(flash[:alert]).to be_present
      end
    end
  end
end
