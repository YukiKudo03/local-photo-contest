# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReactionService, type: :service do
  let(:user) { create(:user, :confirmed) }
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }
  let(:entry) { create(:entry, contest: contest) }

  subject { described_class.new(user) }

  describe "#toggle_like" do
    context "when not yet liked" do
      it "creates a reaction" do
        result = subject.toggle_like(entry)
        expect(result[:success]).to be true
        expect(result[:liked]).to be true
        expect(result[:count]).to eq(1)
      end

      it "awards points" do
        subject.toggle_like(entry)
        expect(user.user_points.where(action_type: "like")).to exist
      end
    end

    context "when already liked" do
      before { create(:reaction, user: user, entry: entry) }

      it "removes the reaction" do
        result = subject.toggle_like(entry)
        expect(result[:success]).to be true
        expect(result[:liked]).to be false
        expect(result[:count]).to eq(0)
      end
    end

    it "returns correct count after multiple toggles" do
      subject.toggle_like(entry)
      result = subject.toggle_like(entry)
      expect(result[:count]).to eq(0)
    end
  end
end
