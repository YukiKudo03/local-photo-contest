# frozen_string_literal: true

require "rails_helper"

RSpec.describe Comment, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:entry) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_most(1000) }
  end

  describe "scopes" do
    let(:organizer) { create(:user, :organizer, :confirmed) }
    let(:contest) { create(:contest, :published, user: organizer) }
    let(:entry) { create(:entry, contest: contest) }

    describe ".recent" do
      let!(:old_comment) { create(:comment, entry: entry, created_at: 2.days.ago) }
      let!(:new_comment) { create(:comment, entry: entry, created_at: 1.day.ago) }

      it "orders by created_at desc" do
        expect(Comment.recent.first).to eq(new_comment)
        expect(Comment.recent.last).to eq(old_comment)
      end
    end

    describe ".oldest" do
      let!(:old_comment) { create(:comment, entry: entry, created_at: 2.days.ago) }
      let!(:new_comment) { create(:comment, entry: entry, created_at: 1.day.ago) }

      it "orders by created_at asc" do
        expect(Comment.oldest.first).to eq(old_comment)
        expect(Comment.oldest.last).to eq(new_comment)
      end
    end
  end

  describe "delegation" do
    let(:organizer) { create(:user, :organizer, :confirmed) }
    let(:contest) { create(:contest, :published, user: organizer) }
    let(:entry) { create(:entry, contest: contest) }
    let(:comment) { create(:comment, entry: entry) }

    it "delegates contest to entry" do
      expect(comment.contest).to eq(contest)
    end
  end
end
