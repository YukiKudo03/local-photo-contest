require "rails_helper"

RSpec.describe TutorialProgress, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    let(:user) { create(:user) }
    subject { build(:tutorial_progress, user: user) }

    it { should validate_presence_of(:tutorial_type) }

    it "validates uniqueness of tutorial_type scoped to user" do
      create(:tutorial_progress, user: user, tutorial_type: "organizer_onboarding")
      duplicate = build(:tutorial_progress, user: user, tutorial_type: "organizer_onboarding")
      expect(duplicate).not_to be_valid
    end

    it "allows same tutorial_type for different users" do
      create(:tutorial_progress, user: user, tutorial_type: "organizer_onboarding")
      other_user = create(:user)
      other_progress = build(:tutorial_progress, user: other_user, tutorial_type: "organizer_onboarding")
      expect(other_progress).to be_valid
    end
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let!(:completed) { create(:tutorial_progress, user: user, tutorial_type: "organizer_onboarding", completed: true, started_at: 1.hour.ago) }
    let!(:in_progress) { create(:tutorial_progress, user: user, tutorial_type: "contest_creation", started_at: Time.current) }
    let!(:skipped) { create(:tutorial_progress, user: user, tutorial_type: "area_management", skipped: true) }
    let!(:not_started) { create(:tutorial_progress, user: user, tutorial_type: "statistics") }

    describe ".completed" do
      it "returns completed progresses" do
        expect(TutorialProgress.completed).to eq([ completed ])
      end
    end

    describe ".in_progress" do
      it "returns in-progress progresses" do
        expect(TutorialProgress.in_progress).to eq([ in_progress ])
      end
    end

    describe ".skipped" do
      it "returns skipped progresses" do
        expect(TutorialProgress.skipped).to eq([ skipped ])
      end
    end

    describe ".not_started" do
      it "returns progresses that have not been started" do
        result = TutorialProgress.not_started
        expect(result).to include(not_started)
        expect(result).not_to include(completed)
        expect(result).not_to include(in_progress)
      end
    end
  end

  describe "instance methods" do
    let(:user) { create(:user) }
    let!(:step1) { create(:tutorial_step, tutorial_type: "organizer_onboarding", step_id: "step1", position: 1) }
    let!(:step2) { create(:tutorial_step, tutorial_type: "organizer_onboarding", step_id: "step2", position: 2) }
    let!(:step3) { create(:tutorial_step, tutorial_type: "organizer_onboarding", step_id: "step3", position: 3) }
    let(:progress) { create(:tutorial_progress, user: user, tutorial_type: "organizer_onboarding") }

    describe "#start!" do
      it "sets started_at and current_step_id" do
        progress.start!
        expect(progress.started_at).to be_present
        expect(progress.current_step_id).to eq("step1")
      end

      it "does nothing if already started" do
        progress.update!(started_at: 1.day.ago, current_step_id: "step2")
        original_started_at = progress.started_at
        progress.start!
        expect(progress.started_at).to eq(original_started_at)
      end
    end

    describe "#advance!" do
      before { progress.start! }

      it "advances to the next step" do
        progress.advance!
        expect(progress.current_step_id).to eq("step2")
      end

      it "completes when on last step" do
        progress.update!(current_step_id: "step3")
        progress.advance!
        expect(progress.completed?).to be true
      end
    end

    describe "#advance_to!" do
      before { progress.start! }

      it "advances to a specific step" do
        expect(progress.advance_to!("step2")).to be true
        expect(progress.current_step_id).to eq("step2")
      end

      it "returns false for invalid step" do
        expect(progress.advance_to!("invalid")).to be false
      end

      it "completes when advancing to last step" do
        progress.advance_to!("step3")
        expect(progress.completed?).to be true
      end
    end

    describe "#complete!" do
      it "sets completed and completed_at" do
        progress.complete!
        expect(progress.completed?).to be true
        expect(progress.completed_at).to be_present
      end
    end

    describe "#skip!" do
      it "sets skipped and completed_at" do
        progress.skip!
        expect(progress.skipped?).to be true
        expect(progress.completed_at).to be_present
      end
    end

    describe "#reset!" do
      before do
        progress.start!
        progress.complete!
      end

      it "resets all progress fields" do
        progress.reset!
        expect(progress.current_step_id).to be_nil
        expect(progress.completed?).to be false
        expect(progress.skipped?).to be false
        expect(progress.started_at).to be_nil
        expect(progress.completed_at).to be_nil
        expect(progress.step_data).to eq({})
      end
    end

    describe "#current_step" do
      it "returns the current step" do
        progress.update!(current_step_id: "step2")
        expect(progress.current_step).to eq(step2)
      end

      it "returns nil when no current step" do
        expect(progress.current_step).to be_nil
      end
    end

    describe "#progress_percentage" do
      it "returns 0 when not started" do
        expect(progress.progress_percentage).to eq(0)
      end

      it "returns 100 when completed" do
        progress.complete!
        expect(progress.progress_percentage).to eq(100)
      end

      it "calculates correct percentage" do
        progress.update!(current_step_id: "step2")
        expect(progress.progress_percentage).to eq(67) # 2/3 * 100 rounded
      end
    end

    describe "#status" do
      it "returns :not_started when not started" do
        expect(progress.status).to eq(:not_started)
      end

      it "returns :in_progress when started" do
        progress.start!
        expect(progress.status).to eq(:in_progress)
      end

      it "returns :completed when completed" do
        progress.complete!
        expect(progress.status).to eq(:completed)
      end

      it "returns :skipped when skipped" do
        progress.skip!
        expect(progress.status).to eq(:skipped)
      end
    end

    describe "#status_label" do
      it "returns correct labels" do
        expect(progress.status_label).to eq("未開始")
        progress.start!
        expect(progress.status_label).to eq("進行中")
        progress.complete!
        expect(progress.status_label).to eq("完了")
      end
    end

    describe "#as_json_for_tutorial" do
      before { progress.start! }

      it "returns correct JSON structure" do
        json = progress.as_json_for_tutorial
        expect(json).to include(
          id: progress.id,
          tutorial_type: "organizer_onboarding",
          current_step_id: "step1",
          completed: false,
          skipped: false,
          status: :in_progress,
          status_label: "進行中",
          total_steps: 3
        )
      end
    end
  end
end
