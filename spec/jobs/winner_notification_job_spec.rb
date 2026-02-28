# frozen_string_literal: true

require "rails_helper"

RSpec.describe WinnerNotificationJob, type: :job do
  include ActiveJob::TestHelper

  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:participant) { create(:user, :confirmed) }

  describe "#perform" do
    context "with contest_id argument" do
      let(:contest) { create(:contest, :accepting_entries, user: organizer) }
      let!(:entry) { create(:entry, contest: contest, user: participant) }

      before do
        contest.finish!
        contest.update_column(:results_announced_at, Time.current)
      end

      let!(:ranking) { create(:contest_ranking, :first_place, contest: contest, entry: entry) }

      it "processes the specified contest" do
        expect {
          described_class.perform_now(contest.id)
        }.to have_enqueued_mail(NotificationMailer, :winner_certificate)
      end

      it "sets winner_notified_at" do
        described_class.perform_now(contest.id)
        expect(ranking.reload.winner_notified_at).to be_present
      end
    end

    context "without arguments (scan mode)" do
      let(:contest) { create(:contest, :accepting_entries, user: organizer) }
      let!(:entry) { create(:entry, contest: contest, user: participant) }

      before do
        contest.finish!
        contest.update_column(:results_announced_at, Time.current)
      end

      let!(:ranking) { create(:contest_ranking, :first_place, contest: contest, entry: entry) }

      it "finds and processes contests with unnotified winners" do
        expect {
          described_class.perform_now
        }.to have_enqueued_mail(NotificationMailer, :winner_certificate)
      end

      it "skips contests where all winners are already notified" do
        ranking.update!(winner_notified_at: 1.hour.ago)

        expect {
          described_class.perform_now
        }.not_to have_enqueued_mail(NotificationMailer, :winner_certificate)
      end
    end

    context "when contest has no results announced" do
      let(:contest) { create(:contest, :accepting_entries, user: organizer) }
      let!(:entry) { create(:entry, contest: contest, user: participant) }

      before { contest.finish! }

      it "does not process the contest" do
        expect {
          described_class.perform_now
        }.not_to have_enqueued_mail(NotificationMailer, :winner_certificate)
      end
    end
  end
end
