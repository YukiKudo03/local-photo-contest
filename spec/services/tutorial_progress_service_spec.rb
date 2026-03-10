# frozen_string_literal: true

require "rails_helper"

RSpec.describe TutorialProgressService, type: :service do
  let(:user) { create(:user, :confirmed) }
  let(:service) { described_class.new(user) }
  let(:tutorial_type) { "organizer_onboarding" }

  describe "#skip_step" do
    let!(:step1) { create(:tutorial_step, tutorial_type: tutorial_type, step_id: "step_a", position: 1) }
    let!(:step2) { create(:tutorial_step, tutorial_type: tutorial_type, step_id: "step_b", position: 2) }
    let!(:step3) { create(:tutorial_step, tutorial_type: tutorial_type, step_id: "step_c", position: 3) }

    context "when progress does not exist" do
      it "returns nil" do
        result = service.skip_step(tutorial_type, "step_a")
        expect(result).to be_nil
      end
    end

    context "when there is a next step" do
      before { service.start(tutorial_type) }

      it "adds step to skipped_steps and advances to next step" do
        result = service.skip_step(tutorial_type, "step_a")
        expect(result[:progress].skipped_steps).to include("step_a")
        expect(result[:progress].current_step_id).to eq("step_b")
        expect(result[:next_step]).to be_present
      end
    end

    context "when there is no next step (last step)" do
      before do
        service.start(tutorial_type)
        service.skip_step(tutorial_type, "step_a")
        service.skip_step(tutorial_type, "step_b")
      end

      it "completes the tutorial with skipped_all method" do
        result = service.skip_step(tutorial_type, "step_c")
        expect(result[:progress].completed).to be true
        expect(result[:progress].completion_method).to eq("skipped_all")
        expect(result[:next_step]).to be_nil
      end
    end
  end
end
