# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserDataExportJob, type: :job do
  include ActiveJob::TestHelper

  let(:user) { create(:user, :confirmed) }
  let!(:export_request) { create(:data_export_request, user: user) }

  describe "#perform" do
    it "updates status from pending to processing to completed" do
      described_class.perform_now(export_request.id)
      export_request.reload
      expect(export_request.status).to eq("completed")
    end

    it "attaches a ZIP file" do
      described_class.perform_now(export_request.id)
      export_request.reload
      expect(export_request.file).to be_attached
    end

    it "sets completed_at and expires_at" do
      described_class.perform_now(export_request.id)
      export_request.reload
      expect(export_request.completed_at).to be_present
      expect(export_request.expires_at).to be_present
      expect(export_request.expires_at).to be > 6.days.from_now
    end

    it "sends a completion email" do
      expect {
        described_class.perform_now(export_request.id)
      }.to have_enqueued_mail(DataExportMailer, :export_ready)
    end
  end
end
