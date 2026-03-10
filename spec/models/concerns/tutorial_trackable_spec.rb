# frozen_string_literal: true

require "rails_helper"

RSpec.describe TutorialTrackable do
  let(:participant) { create(:user, :confirmed, role: :participant) }
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:admin) { create(:user, :admin, :confirmed) }

  describe "#can_access_feature?" do
    it "returns true for participant base features" do
      expect(participant.can_access_feature?("view_contests")).to be true
    end

    it "returns true for organizer base features" do
      expect(organizer.can_access_feature?("view_dashboard")).to be true
    end

    it "returns true for any feature for admin" do
      expect(admin.can_access_feature?("anything")).to be true
    end

    it "returns false for unknown role base features" do
      allow(participant).to receive(:role).and_return("unknown")
      expect(participant.can_access_feature?("view_contests")).to be false
    end

    it "returns true for unlocked features" do
      FeatureUnlock.unlock!(participant, "submit_entry", "first_vote")
      expect(participant.can_access_feature?("submit_entry")).to be true
    end

    it "returns false for non-unlocked features" do
      expect(participant.can_access_feature?("submit_entry")).to be false
    end
  end

  describe "#available_features" do
    it "returns participant base features plus unlocked" do
      FeatureUnlock.unlock!(participant, "submit_entry", "first_vote")
      features = participant.available_features
      expect(features).to include("view_contests", "view_entries", "vote", "submit_entry")
    end

    it "returns organizer base features" do
      features = organizer.available_features
      expect(features).to include("view_dashboard", "create_contest_from_template", "basic_moderation")
    end

    it "returns admin base features" do
      features = admin.available_features
      expect(features).to include("view_admin_dashboard", "manage_users", "manage_contests")
    end

    it "returns empty base for unknown role" do
      allow(participant).to receive(:role).and_return("unknown")
      expect(participant.available_features).to eq([])
    end
  end

  describe "#update_feature_level!" do
    context "organizer" do
      it "stays beginner without milestones" do
        organizer.update_feature_level!
        expect(organizer.feature_level).to eq("beginner")
      end

      it "becomes intermediate with first_contest_published milestone" do
        organizer.milestones.create!(milestone_type: "first_contest_published", achieved_at: Time.current)
        organizer.update_feature_level!
        expect(organizer.feature_level).to eq("intermediate")
      end

      it "becomes advanced with first_contest_completed milestone" do
        organizer.milestones.create!(milestone_type: "first_contest_completed", achieved_at: Time.current)
        organizer.update_feature_level!
        expect(organizer.feature_level).to eq("advanced")
      end
    end

    context "participant" do
      it "stays beginner without milestones" do
        participant.update_feature_level!
        expect(participant.feature_level).to eq("beginner")
      end

      it "becomes intermediate with first_submission milestone" do
        participant.milestones.create!(milestone_type: "first_submission", achieved_at: Time.current)
        participant.update_feature_level!
        expect(participant.feature_level).to eq("intermediate")
      end
    end

    context "admin" do
      it "is always advanced" do
        admin.update_feature_level!
        expect(admin.feature_level).to eq("advanced")
      end
    end

    it "does not update if level is unchanged" do
      participant.update!(feature_level: :beginner)
      expect(participant).not_to receive(:update!).with(feature_level: "beginner")
      participant.update_feature_level!
    end
  end
end
