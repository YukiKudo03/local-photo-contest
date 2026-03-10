# frozen_string_literal: true

require "rails_helper"

RSpec.describe WinnerNotificationService, type: :service do
  include ActiveJob::TestHelper

  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:participant) { create(:user, :confirmed) }
  let(:contest) { create(:contest, :accepting_entries, user: organizer) }
  let!(:entry) { create(:entry, contest: contest, user: participant) }
  let!(:entry2) { create(:entry, contest: contest) }

  before do
    contest.finish!
    contest.update_column(:results_announced_at, Time.current)
  end

  describe "#notify_winners!" do
    let!(:ranking) { create(:contest_ranking, :first_place, contest: contest, entry: entry) }

    it "sends winner notification email to prize winners" do
      expect {
        described_class.new(contest).notify_winners!
      }.to have_enqueued_mail(NotificationMailer, :winner_certificate)
    end

    it "creates in-app notification for winners" do
      expect {
        described_class.new(contest).notify_winners!
      }.to change(Notification, :count).by(1)
    end

    it "sets winner_notified_at on rankings" do
      described_class.new(contest).notify_winners!
      expect(ranking.reload.winner_notified_at).to be_present
    end

    it "generates certificates before notifying" do
      described_class.new(contest).notify_winners!
      expect(ranking.reload.certificate_pdf).to be_attached
    end

    it "skips already-notified rankings" do
      ranking.update!(winner_notified_at: 1.hour.ago)

      expect {
        described_class.new(contest).notify_winners!
      }.not_to have_enqueued_mail(NotificationMailer, :winner_certificate)
    end

    context "when user has email disabled for results" do
      before { participant.update!(email_on_results: false) }

      it "still creates in-app notification" do
        expect {
          described_class.new(contest).notify_winners!
        }.to change(Notification, :count).by(1)
      end
    end

    context "with non-prize rankings" do
      let!(:ranking_no_prize) do
        create(:contest_ranking, contest: contest, entry: entry2, rank: 4, total_score: 50.0)
      end

      it "only notifies prize winners" do
        expect {
          described_class.new(contest).notify_winners!
        }.to have_enqueued_mail(NotificationMailer, :winner_certificate).once
      end
    end

    context "when an error occurs for one ranking" do
      it "logs error and continues processing other rankings" do
        allow_any_instance_of(CertificateGenerationService).to receive(:generate_and_attach!).and_raise(StandardError, "cert error")
        expect(Rails.logger).to receive(:error).with(/Winner notification failed/)
        described_class.new(contest).notify_winners!
      end
    end
  end
end
