# frozen_string_literal: true

require "rails_helper"

RSpec.describe EntryChannel, type: :channel do
  let(:user) { create(:user, :confirmed) }

  before do
    stub_connection current_user: user
  end

  describe "#subscribed" do
    context "with a valid entry_id" do
      let(:entry) { create(:entry) }

      it "streams for the entry" do
        subscribe(entry_id: entry.id)

        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_for(entry)
      end
    end

    context "with an invalid entry_id" do
      it "raises ActiveRecord::RecordNotFound" do
        expect {
          subscribe(entry_id: -1)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#unsubscribed" do
    let(:entry) { create(:entry) }

    it "stops all streams" do
      subscribe(entry_id: entry.id)
      unsubscribe

      expect(subscription).not_to have_streams
    end
  end
end
