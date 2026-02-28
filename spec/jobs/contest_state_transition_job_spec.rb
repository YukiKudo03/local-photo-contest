# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContestStateTransitionJob, type: :job do
  include ActiveJob::TestHelper

  describe "#perform" do
    let(:organizer) { create(:user, :organizer, :confirmed) }

    context "auto-publish" do
      let!(:contest) { create(:contest, :past_scheduled_publish, user: organizer) }

      it "publishes draft contests whose scheduled_publish_at has passed" do
        described_class.perform_now
        expect(contest.reload).to be_published
      end

      it "does not publish drafts whose scheduled_publish_at is in the future" do
        future_contest = create(:contest, :scheduled_for_publish, user: organizer)
        described_class.perform_now
        expect(future_contest.reload).to be_draft
      end

      it "does not publish already-published contests" do
        published = create(:contest, :published, user: organizer)
        described_class.perform_now
        expect(published.reload).to be_published
      end

      it "does not publish deleted contests" do
        deleted = create(:contest, :past_scheduled_publish, :deleted, user: organizer)
        described_class.perform_now
        expect(deleted.reload).to be_draft
      end
    end

    context "auto-finish" do
      let!(:contest) { create(:contest, :past_scheduled_finish, user: organizer) }

      it "finishes published contests whose scheduled_finish_at has passed" do
        described_class.perform_now
        expect(contest.reload).to be_finished
      end

      it "does not finish contests whose scheduled_finish_at is in the future" do
        future_contest = create(:contest, :scheduled_for_finish, user: organizer)
        described_class.perform_now
        expect(future_contest.reload).to be_published
      end

      it "does not finish already-finished contests" do
        finished = create(:contest, :finished, user: organizer)
        described_class.perform_now
        expect(finished.reload).to be_finished
      end

      it "does not finish deleted contests" do
        deleted = create(:contest, :past_scheduled_finish, :deleted, user: organizer)
        described_class.perform_now
        expect(deleted.reload).to be_published
      end
    end

    context "with multiple contests" do
      let!(:publish_eligible) { create(:contest, :past_scheduled_publish, user: organizer) }
      let!(:finish_eligible) { create(:contest, :past_scheduled_finish, user: organizer) }

      it "processes all eligible contests in a single run" do
        described_class.perform_now
        expect(publish_eligible.reload).to be_published
        expect(finish_eligible.reload).to be_finished
      end
    end

    context "error handling" do
      let!(:good_contest) { create(:contest, :past_scheduled_finish, user: organizer) }

      it "continues processing if one contest raises an error" do
        bad_contest = create(:contest, :past_scheduled_publish, user: organizer)
        bad_contest.update_column(:title, "")

        expect(Rails.logger).to receive(:error).with(/Auto-publish failed/)
        described_class.perform_now

        expect(good_contest.reload).to be_finished
      end
    end

    context "idempotency" do
      let!(:contest) { create(:contest, :past_scheduled_publish, user: organizer) }

      it "is safe to run multiple times" do
        described_class.perform_now
        expect(contest.reload).to be_published
        expect { described_class.perform_now }.not_to raise_error
      end
    end
  end
end
