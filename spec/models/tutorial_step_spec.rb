require "rails_helper"

RSpec.describe TutorialStep, type: :model do
  describe "validations" do
    subject { build(:tutorial_step) }

    it { should validate_presence_of(:tutorial_type) }
    it { should validate_presence_of(:step_id) }
    it { should validate_presence_of(:position) }
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_most(15).with_message("は15文字以内で入力してください") }
    it { should validate_length_of(:description).is_at_most(40).with_message("は40文字以内で入力してください").allow_blank }
    it { should validate_numericality_of(:position).only_integer.is_greater_than(0) }

    it "validates uniqueness of step_id scoped to tutorial_type" do
      create(:tutorial_step, tutorial_type: "organizer_onboarding", step_id: "welcome", position: 1)
      duplicate = build(:tutorial_step, tutorial_type: "organizer_onboarding", step_id: "welcome", position: 2)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:step_id]).to be_present
    end

    it "allows same step_id for different tutorial types" do
      create(:tutorial_step, tutorial_type: "organizer_onboarding", step_id: "welcome")
      different_type = build(:tutorial_step, tutorial_type: "participant_onboarding", step_id: "welcome")
      expect(different_type).to be_valid
    end

    it "validates tutorial_type inclusion" do
      invalid_step = build(:tutorial_step, tutorial_type: "invalid_type")
      expect(invalid_step).not_to be_valid
    end

    it "validates tooltip_position inclusion" do
      invalid_step = build(:tutorial_step, tooltip_position: "invalid")
      expect(invalid_step).not_to be_valid
    end
  end

  describe "scopes" do
    let!(:step1) { create(:tutorial_step, tutorial_type: "organizer_onboarding", position: 1) }
    let!(:step2) { create(:tutorial_step, tutorial_type: "organizer_onboarding", position: 2) }
    let!(:step3) { create(:tutorial_step, tutorial_type: "participant_onboarding", position: 1) }

    describe ".for_type" do
      it "returns steps for the specified tutorial type ordered by position" do
        result = TutorialStep.for_type("organizer_onboarding")
        expect(result).to eq([step1, step2])
      end
    end

    describe ".ordered" do
      it "returns steps ordered by position" do
        expect(TutorialStep.ordered.first).to eq(step1)
      end
    end
  end

  describe "class methods" do
    describe ".types_for_role" do
      it "returns correct types for participant" do
        expect(TutorialStep.types_for_role("participant")).to include("participant_onboarding")
      end

      it "returns correct types for organizer" do
        expect(TutorialStep.types_for_role("organizer")).to include("organizer_onboarding")
      end

      it "returns correct types for admin" do
        expect(TutorialStep.types_for_role("admin")).to include("admin_onboarding")
      end
    end

    describe ".onboarding_type_for_role" do
      it "returns participant_onboarding for participant" do
        expect(TutorialStep.onboarding_type_for_role("participant")).to eq("participant_onboarding")
      end

      it "returns organizer_onboarding for organizer" do
        expect(TutorialStep.onboarding_type_for_role("organizer")).to eq("organizer_onboarding")
      end

      it "returns admin_onboarding for admin" do
        expect(TutorialStep.onboarding_type_for_role("admin")).to eq("admin_onboarding")
      end
    end
  end

  describe "instance methods" do
    let!(:step1) { create(:tutorial_step, tutorial_type: "organizer_onboarding", step_id: "step1", position: 1) }
    let!(:step2) { create(:tutorial_step, tutorial_type: "organizer_onboarding", step_id: "step2", position: 2) }
    let!(:step3) { create(:tutorial_step, tutorial_type: "organizer_onboarding", step_id: "step3", position: 3) }

    describe "#next_step" do
      it "returns the next step" do
        expect(step1.next_step).to eq(step2)
        expect(step2.next_step).to eq(step3)
      end

      it "returns nil for the last step" do
        expect(step3.next_step).to be_nil
      end
    end

    describe "#previous_step" do
      it "returns the previous step" do
        expect(step3.previous_step).to eq(step2)
        expect(step2.previous_step).to eq(step1)
      end

      it "returns nil for the first step" do
        expect(step1.previous_step).to be_nil
      end
    end

    describe "#first_step?" do
      it "returns true for position 1" do
        expect(step1.first_step?).to be true
      end

      it "returns false for other positions" do
        expect(step2.first_step?).to be false
      end
    end

    describe "#last_step?" do
      it "returns true when there is no next step" do
        expect(step3.last_step?).to be true
      end

      it "returns false when there is a next step" do
        expect(step1.last_step?).to be false
      end
    end

    describe "#as_json_for_tutorial" do
      it "returns correct JSON structure" do
        json = step1.as_json_for_tutorial
        expect(json).to include(
          id: step1.id,
          step_id: step1.step_id,
          position: step1.position,
          title: step1.title,
          is_first: true,
          is_last: false
        )
      end
    end
  end
end
