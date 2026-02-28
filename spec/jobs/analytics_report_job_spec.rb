# frozen_string_literal: true

require "rails_helper"

RSpec.describe AnalyticsReportJob, type: :job do
  let(:organizer) { create(:user, :organizer, :confirmed) }

  describe "#perform" do
    context "without contest_id" do
      it "generates reports for published contests" do
        contest = create(:contest, :published, user: organizer)
        create(:contest, user: organizer, status: :draft)

        expect {
          described_class.new.perform
        }.to change { contest.reload.analytics_report_pdf.attached? }.from(false).to(true)
      end

      it "generates reports for finished contests" do
        contest = create(:contest, user: organizer, status: :finished)

        described_class.new.perform
        expect(contest.reload.analytics_report_pdf).to be_attached
      end

      it "skips draft contests" do
        contest = create(:contest, user: organizer, status: :draft)

        described_class.new.perform
        expect(contest.reload.analytics_report_pdf).not_to be_attached
      end
    end

    context "with contest_id" do
      it "generates report for specified contest only" do
        contest1 = create(:contest, :published, user: organizer)
        contest2 = create(:contest, :published, user: organizer)

        described_class.new.perform(contest1.id)
        expect(contest1.reload.analytics_report_pdf).to be_attached
        expect(contest2.reload.analytics_report_pdf).not_to be_attached
      end
    end

    context "when error occurs" do
      it "continues processing other contests" do
        contest1 = create(:contest, :published, user: organizer)
        contest2 = create(:contest, :published, user: organizer)

        allow(AnalyticsReportService).to receive(:new).and_call_original
        allow(AnalyticsReportService).to receive(:new).with(contest1).and_raise(StandardError, "test error")

        expect {
          described_class.new.perform
        }.not_to raise_error

        expect(contest2.reload.analytics_report_pdf).to be_attached
      end
    end
  end
end
