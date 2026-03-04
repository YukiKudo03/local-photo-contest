# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reaction, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:entry) }
  end

  describe "validations" do
    subject { build(:reaction) }

    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to([ :entry_id, :reaction_type ]) }
    it { is_expected.to validate_presence_of(:reaction_type) }
    it { is_expected.to validate_inclusion_of(:reaction_type).in_array(Reaction::TYPES) }
  end

  describe "scopes" do
    let(:user) { create(:user, :confirmed) }
    let(:organizer) { create(:user, :organizer, :confirmed) }
    let(:contest) { create(:contest, :published, user: organizer) }
    let(:entry1) { create(:entry, contest: contest) }
    let(:entry2) { create(:entry, contest: contest) }
    let!(:reaction1) { create(:reaction, user: user, entry: entry1) }
    let!(:reaction2) { create(:reaction, entry: entry2) }

    it "by_user returns reactions by specified user" do
      expect(described_class.by_user(user)).to contain_exactly(reaction1)
    end

    it "by_entry returns reactions for specified entry" do
      expect(described_class.by_entry(entry1)).to contain_exactly(reaction1)
    end

    it "likes returns only like reactions" do
      expect(described_class.likes.count).to eq(2)
    end
  end

  describe "counter cache" do
    let(:organizer) { create(:user, :organizer, :confirmed) }
    let(:contest) { create(:contest, :published, user: organizer) }
    let(:entry) { create(:entry, contest: contest) }
    let(:user) { create(:user, :confirmed) }

    it "increments reactions_count on entry when created" do
      expect {
        create(:reaction, user: user, entry: entry)
      }.to change { entry.reload.reactions_count }.by(1)
    end

    it "decrements reactions_count on entry when destroyed" do
      reaction = create(:reaction, user: user, entry: entry)
      expect {
        reaction.destroy!
      }.to change { entry.reload.reactions_count }.by(-1)
    end
  end
end
