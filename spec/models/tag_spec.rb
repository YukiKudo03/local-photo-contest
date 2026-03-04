# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tag, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:entry_tags).dependent(:destroy) }
    it { is_expected.to have_many(:entries).through(:entry_tags) }
  end

  describe "validations" do
    subject { build(:tag) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
    it { is_expected.to validate_length_of(:category).is_at_most(50) }
  end

  describe "scopes" do
    let!(:popular_tag) { create(:tag, name: "popular", entries_count: 10) }
    let!(:unpopular_tag) { create(:tag, name: "unpopular", entries_count: 1) }
    let!(:scene_tag) { create(:tag, name: "sunset", category: "scene") }
    let!(:object_tag) { create(:tag, name: "car", category: "object") }

    describe ".popular" do
      it "orders tags by entries_count desc" do
        expect(Tag.popular.first).to eq(popular_tag)
      end
    end

    describe ".by_category" do
      it "filters tags by category" do
        expect(Tag.by_category("scene")).to contain_exactly(scene_tag)
      end
    end

    describe ".alphabetical" do
      it "orders tags alphabetically" do
        tags = Tag.alphabetical
        expect(tags.map(&:name)).to eq(tags.map(&:name).sort)
      end
    end
  end

  describe "factory" do
    it "creates a valid tag" do
      expect(build(:tag)).to be_valid
    end
  end
end
