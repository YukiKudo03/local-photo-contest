# frozen_string_literal: true

require "rails_helper"

RSpec.describe LevelCalculator do
  describe ".level_for" do
    it "returns level 1 for 0 points" do
      expect(described_class.level_for(0)).to eq(1)
    end

    it "returns level 2 for 50 points" do
      expect(described_class.level_for(50)).to eq(2)
    end

    it "returns level 3 for 150 points" do
      expect(described_class.level_for(150)).to eq(3)
    end

    it "returns level 5 for 500 points" do
      expect(described_class.level_for(500)).to eq(5)
    end

    it "returns level 10 for 2000 points" do
      expect(described_class.level_for(2000)).to eq(10)
    end
  end

  describe ".points_for_level" do
    it "returns 0 for level 1" do
      expect(described_class.points_for_level(1)).to eq(0)
    end

    it "returns 50 for level 2" do
      expect(described_class.points_for_level(2)).to eq(50)
    end
  end

  describe ".progress_to_next_level" do
    it "returns 0% for 0 points" do
      result = described_class.progress_to_next_level(0)
      expect(result[:current_level]).to eq(1)
      expect(result[:current_points]).to eq(0)
      expect(result[:points_to_next]).to eq(50)
      expect(result[:progress_percent]).to eq(0)
    end

    it "returns 50% when halfway to next level" do
      result = described_class.progress_to_next_level(25)
      expect(result[:progress_percent]).to eq(50)
    end

    it "returns 100% at max level" do
      result = described_class.progress_to_next_level(2000)
      expect(result[:current_level]).to eq(10)
      expect(result[:progress_percent]).to eq(100)
    end
  end

  describe "LEVEL_THRESHOLDS" do
    it "has monotonically increasing thresholds" do
      thresholds = LevelCalculator::LEVEL_THRESHOLDS
      thresholds.each_cons(2) do |a, b|
        expect(b).to be > a
      end
    end
  end
end
