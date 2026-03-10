# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContestChannel, type: :channel do
  let(:user) { create(:user, :confirmed) }

  before do
    stub_connection current_user: user
  end

  describe "#subscribed" do
    context "with a valid contest_id" do
      let(:contest) { create(:contest) }

      it "streams for the contest" do
        subscribe(contest_id: contest.id)

        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_for(contest)
      end
    end

    context "with an invalid contest_id" do
      it "raises ActiveRecord::RecordNotFound" do
        expect {
          subscribe(contest_id: -1)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#unsubscribed" do
    let(:contest) { create(:contest) }

    it "stops all streams" do
      subscribe(contest_id: contest.id)
      unsubscribe

      expect(subscription).not_to have_streams
    end
  end
end
