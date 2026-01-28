# frozen_string_literal: true

require "rails_helper"

RSpec.describe EvaluationCriterion, type: :model do
  describe "associations" do
    it { should belong_to(:contest) }
    it { should have_many(:judge_evaluations).dependent(:destroy) }
  end

  describe "validations" do
    let(:contest) { create(:contest, :published) }

    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(50) }
    it { should validate_length_of(:description).is_at_most(500) }
    it { should validate_presence_of(:max_score) }
    it { should validate_numericality_of(:max_score).only_integer.is_greater_than(0).is_less_than_or_equal_to(100) }

    it "validates uniqueness of name scoped to contest_id" do
      create(:evaluation_criterion, contest: contest, name: "TestCriterion")
      duplicate = build(:evaluation_criterion, contest: contest, name: "TestCriterion")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("は既にこのコンテストに登録されています")
    end
  end

  describe "scopes" do
    describe ".ordered" do
      let(:contest) { create(:contest, :published) }
      let!(:criterion2) { create(:evaluation_criterion, contest: contest, position: 2, name: "Criterion2") }
      let!(:criterion1) { create(:evaluation_criterion, contest: contest, position: 1, name: "Criterion1") }
      let!(:criterion3) { create(:evaluation_criterion, contest: contest, position: 3, name: "Criterion3") }

      it "returns criteria ordered by position" do
        expect(contest.evaluation_criteria.ordered).to eq([ criterion1, criterion2, criterion3 ])
      end
    end
  end

  describe "callbacks" do
    describe "#set_position" do
      let(:contest) { create(:contest, :published) }

      it "sets position automatically if not provided" do
        criterion = create(:evaluation_criterion, contest: contest, position: nil, name: "Auto")
        expect(criterion.position).to be_present
      end

      it "increments position based on existing criteria" do
        create(:evaluation_criterion, contest: contest, position: 5, name: "First")
        criterion = create(:evaluation_criterion, contest: contest, position: nil, name: "Second")
        expect(criterion.position).to eq(6)
      end
    end
  end

  describe "default values" do
    let(:contest) { create(:contest, :published) }

    it "defaults max_score to 10" do
      criterion = EvaluationCriterion.create!(contest: contest, name: "Test")
      expect(criterion.max_score).to eq(10)
    end
  end
end
