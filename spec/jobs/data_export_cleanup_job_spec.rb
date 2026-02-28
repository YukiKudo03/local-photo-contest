# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataExportCleanupJob, type: :job do
  let(:user) { create(:user, :confirmed) }

  describe "#perform" do
    it "marks expired exports as expired" do
      export = create(:data_export_request, :completed, user: user, expires_at: 1.day.ago)
      described_class.perform_now
      expect(export.reload.status).to eq("expired")
    end

    it "does not affect non-expired exports" do
      export = create(:data_export_request, :completed, user: user, expires_at: 5.days.from_now)
      described_class.perform_now
      expect(export.reload.status).to eq("completed")
    end
  end
end
