# frozen_string_literal: true

require "rails_helper"

RSpec.describe ContestTemplate, type: :model do
  let(:organizer) { create(:user, :organizer, :confirmed) }

  describe "validations" do
    it "is valid with valid attributes" do
      template = build(:contest_template, user: organizer)
      expect(template).to be_valid
    end

    it "is invalid without a name" do
      template = build(:contest_template, user: organizer, name: nil)
      expect(template).not_to be_valid
      expect(template.errors[:name]).to include("を入力してください")
    end

    it "is invalid with a name longer than 100 characters" do
      template = build(:contest_template, user: organizer, name: "a" * 101)
      expect(template).not_to be_valid
      expect(template.errors[:name]).to include("は100文字以下で入力してください")
    end

    it "is invalid with duplicate name for same user" do
      create(:contest_template, user: organizer, name: "テンプレート1")
      template = build(:contest_template, user: organizer, name: "テンプレート1")
      expect(template).not_to be_valid
      expect(template.errors[:name]).to include("はすでに使用されています")
    end

    it "is valid with same name for different users" do
      other_organizer = create(:user, :organizer, :confirmed)
      create(:contest_template, user: organizer, name: "テンプレート1")
      template = build(:contest_template, user: other_organizer, name: "テンプレート1")
      expect(template).to be_valid
    end

    it "validates judge_weight range" do
      template = build(:contest_template, user: organizer, judge_weight: 101)
      expect(template).not_to be_valid

      template = build(:contest_template, user: organizer, judge_weight: -1)
      expect(template).not_to be_valid

      template = build(:contest_template, user: organizer, judge_weight: 70)
      expect(template).to be_valid
    end

    it "validates prize_count range" do
      template = build(:contest_template, user: organizer, prize_count: 0)
      expect(template).not_to be_valid

      template = build(:contest_template, user: organizer, prize_count: 11)
      expect(template).not_to be_valid

      template = build(:contest_template, user: organizer, prize_count: 5)
      expect(template).to be_valid
    end

    it "validates moderation_threshold range" do
      template = build(:contest_template, user: organizer, moderation_threshold: 101)
      expect(template).not_to be_valid

      template = build(:contest_template, user: organizer, moderation_threshold: -1)
      expect(template).not_to be_valid

      template = build(:contest_template, user: organizer, moderation_threshold: 80)
      expect(template).to be_valid
    end
  end

  describe "associations" do
    it "belongs to user" do
      template = create(:contest_template, user: organizer)
      expect(template.user).to eq(organizer)
    end

    it "belongs to source_contest (optional)" do
      contest = create(:contest, user: organizer)
      template = create(:contest_template, user: organizer, source_contest: contest)
      expect(template.source_contest).to eq(contest)
    end

    it "allows nil source_contest" do
      template = create(:contest_template, user: organizer, source_contest: nil)
      expect(template.source_contest).to be_nil
    end

    it "belongs to category (optional)" do
      category = create(:category)
      template = create(:contest_template, user: organizer, category: category)
      expect(template.category).to eq(category)
    end

    it "belongs to area (optional)" do
      area = create(:area, user: organizer)
      template = create(:contest_template, user: organizer, area: area)
      expect(template.area).to eq(area)
    end
  end

  describe "scopes" do
    describe ".owned_by" do
      it "returns templates owned by the specified user" do
        other_organizer = create(:user, :organizer, :confirmed)
        template1 = create(:contest_template, user: organizer)
        template2 = create(:contest_template, user: other_organizer)

        expect(ContestTemplate.owned_by(organizer)).to include(template1)
        expect(ContestTemplate.owned_by(organizer)).not_to include(template2)
      end
    end

    describe ".recent" do
      it "returns templates ordered by created_at desc" do
        template1 = create(:contest_template, user: organizer, created_at: 2.days.ago)
        template2 = create(:contest_template, user: organizer, created_at: 1.day.ago)
        template3 = create(:contest_template, user: organizer, created_at: Time.current)

        expect(ContestTemplate.recent.to_a).to eq([ template3, template2, template1 ])
      end
    end
  end

  describe "#owned_by?" do
    it "returns true if the template is owned by the given user" do
      template = create(:contest_template, user: organizer)
      expect(template.owned_by?(organizer)).to be true
    end

    it "returns false if the template is not owned by the given user" do
      other_organizer = create(:user, :organizer, :confirmed)
      template = create(:contest_template, user: organizer)
      expect(template.owned_by?(other_organizer)).to be false
    end
  end

  describe "#source_contest_title" do
    it "returns source contest title when source contest exists" do
      contest = create(:contest, user: organizer, title: "元コンテスト")
      template = create(:contest_template, user: organizer, source_contest: contest)
      expect(template.source_contest_title).to eq("元コンテスト")
    end

    it "returns '(削除済み)' when source contest is nil" do
      template = create(:contest_template, user: organizer, source_contest: nil)
      expect(template.source_contest_title).to eq("(削除済み)")
    end
  end
end
