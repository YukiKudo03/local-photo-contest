# frozen_string_literal: true

require "rails_helper"

RSpec.describe TutorialsHelper, type: :helper do
  describe "#tutorial_target" do
    it "returns data attribute hash" do
      expect(helper.tutorial_target("step1")).to eq({ "data-tutorial": "step1" })
    end
  end

  describe "#render_tutorial_container" do
    context "when current_user is nil" do
      before { allow(helper).to receive(:current_user).and_return(nil) }

      it "returns nil" do
        expect(helper.render_tutorial_container).to be_nil
      end
    end

    context "when tutorial is disabled" do
      let(:user) { create(:user, :confirmed, tutorial_settings: { "show_tutorials" => false }) }
      before { allow(helper).to receive(:current_user).and_return(user) }

      it "returns nil" do
        expect(helper.render_tutorial_container).to be_nil
      end
    end

    context "when tutorial is enabled" do
      let(:user) { create(:user, :confirmed) }
      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(user).to receive(:tutorial_enabled?).and_return(true)
        allow(helper).to receive(:render).and_return("rendered")
      end

      it "calls render with tutorial_container partial" do
        expect(helper).to receive(:render).with(hash_including(partial: "tutorials/tutorial_container"))
        helper.render_tutorial_container
      end
    end
  end

  describe "#render_welcome_modal" do
    context "when current_user is nil" do
      before { allow(helper).to receive(:current_user).and_return(nil) }

      it "returns nil" do
        expect(helper.render_welcome_modal).to be_nil
      end
    end

    context "when should show onboarding" do
      let(:user) { create(:user, :confirmed) }
      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(user).to receive(:should_show_onboarding?).and_return(true)
        allow(helper).to receive(:render).and_return("rendered")
      end

      it "calls render with welcome_modal partial" do
        expect(helper).to receive(:render).with(partial: "tutorials/welcome_modal")
        helper.render_welcome_modal
      end
    end
  end

  describe "#render_tutorial_help_button" do
    context "when current_user is nil" do
      before { allow(helper).to receive(:current_user).and_return(nil) }

      it "returns nil" do
        expect(helper.render_tutorial_help_button("participant_onboarding")).to be_nil
      end
    end

    context "when tutorial is enabled" do
      let(:user) { create(:user, :confirmed) }
      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(user).to receive(:tutorial_enabled?).and_return(true)
        allow(helper).to receive(:render).and_return("rendered")
      end

      it "calls render with help_button partial" do
        expect(helper).to receive(:render).with(hash_including(partial: "tutorials/help_button"))
        helper.render_tutorial_help_button("participant_onboarding")
      end
    end
  end

  describe "#tutorial_progress_for" do
    context "when current_user is nil" do
      before { allow(helper).to receive(:current_user).and_return(nil) }

      it "returns nil" do
        expect(helper.tutorial_progress_for("participant_onboarding")).to be_nil
      end
    end
  end

  describe "#tutorial_completed?" do
    context "when current_user is nil" do
      before { allow(helper).to receive(:current_user).and_return(nil) }

      it "returns nil" do
        expect(helper.tutorial_completed?("participant_onboarding")).to be_nil
      end
    end
  end

  describe "#tutorial_step_count" do
    it "returns count of steps for the given type" do
      create(:tutorial_step, tutorial_type: "participant_onboarding", step_id: "s1", position: 1)
      create(:tutorial_step, tutorial_type: "participant_onboarding", step_id: "s2", position: 2)
      expect(helper.tutorial_step_count("participant_onboarding")).to eq(2)
    end
  end

  describe "#tutorial_type_label" do
    it "returns label for known type" do
      expect(helper.tutorial_type_label("participant_onboarding")).to eq("参加者向けガイド")
    end

    it "returns label for organizer_onboarding" do
      expect(helper.tutorial_type_label("organizer_onboarding")).to eq("運営者向けガイド")
    end

    it "returns input for unknown type" do
      expect(helper.tutorial_type_label("unknown_type")).to eq("unknown_type")
    end
  end

  describe "#tutorial_status_class" do
    let(:user) { create(:user, :confirmed) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context "when status is completed" do
      it "returns green classes" do
        progress = double("TutorialProgress", status: :completed)
        allow(user).to receive(:tutorial_progress_for).and_return(progress)

        expect(helper.tutorial_status_class("participant_onboarding")).to eq("text-green-600 bg-green-100")
      end
    end

    context "when status is in_progress" do
      it "returns blue classes" do
        progress = double("TutorialProgress", status: :in_progress)
        allow(user).to receive(:tutorial_progress_for).and_return(progress)

        expect(helper.tutorial_status_class("participant_onboarding")).to eq("text-blue-600 bg-blue-100")
      end
    end

    context "when status is skipped" do
      it "returns gray classes" do
        progress = double("TutorialProgress", status: :skipped)
        allow(user).to receive(:tutorial_progress_for).and_return(progress)

        expect(helper.tutorial_status_class("participant_onboarding")).to eq("text-gray-500 bg-gray-100")
      end
    end

    context "when no progress exists" do
      it "returns default gray classes" do
        allow(user).to receive(:tutorial_progress_for).and_return(nil)

        expect(helper.tutorial_status_class("participant_onboarding")).to eq("text-gray-400 bg-gray-50")
      end
    end
  end

  describe "#tutorial_status_label" do
    let(:user) { create(:user, :confirmed) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context "with progress" do
      it "returns status label from progress" do
        progress = double("TutorialProgress", status_label: "進行中")
        allow(user).to receive(:tutorial_progress_for).and_return(progress)

        expect(helper.tutorial_status_label("participant_onboarding")).to eq("進行中")
      end
    end

    context "without progress" do
      it "returns default label" do
        allow(user).to receive(:tutorial_progress_for).and_return(nil)

        expect(helper.tutorial_status_label("participant_onboarding")).to eq("未開始")
      end
    end
  end

  describe "#tutorial_progress_percentage" do
    let(:user) { create(:user, :confirmed) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context "with progress" do
      it "returns percentage" do
        progress = double("TutorialProgress", progress_percentage: 75)
        allow(user).to receive(:tutorial_progress_for).and_return(progress)

        expect(helper.tutorial_progress_percentage("participant_onboarding")).to eq(75)
      end
    end

    context "without progress" do
      it "returns 0" do
        allow(user).to receive(:tutorial_progress_for).and_return(nil)

        expect(helper.tutorial_progress_percentage("participant_onboarding")).to eq(0)
      end
    end
  end

  describe "#context_help" do
    context "when context help is enabled" do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it "returns span tag with icon=true (default)" do
        result = helper.context_help(title: "ヘルプ", content: "テスト内容")

        expect(result).to include("context-help-trigger")
        expect(result).to include("?")
      end

      it "returns data attrs hash with icon=false" do
        result = helper.context_help(title: "ヘルプ", content: "テスト内容", icon: false)

        expect(result).to be_a(Hash)
        expect(result[:controller]).to eq("context-help")
        expect(result[:"context-help-title-value"]).to eq("ヘルプ")
        expect(result[:"context-help-content-value"]).to eq("テスト内容")
      end
    end

    context "when context help is disabled" do
      let(:user) { create(:user, :confirmed) }

      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(user).to receive(:tutorial_settings).and_return({ "show_context_help" => false })
      end

      it "returns empty string" do
        result = helper.context_help(title: "ヘルプ", content: "テスト内容")

        expect(result).to eq("")
      end
    end
  end

  describe "#context_help_enabled?" do
    context "without current_user" do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it "returns true" do
        expect(helper.context_help_enabled?).to be true
      end
    end

    context "with user having show_context_help disabled" do
      let(:user) { create(:user, :confirmed) }

      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(user).to receive(:tutorial_settings).and_return({ "show_context_help" => false })
      end

      it "returns false" do
        expect(helper.context_help_enabled?).to be false
      end
    end

    context "with user having default settings" do
      let(:user) { create(:user, :confirmed) }

      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(user).to receive(:tutorial_settings).and_return({})
      end

      it "returns true" do
        expect(helper.context_help_enabled?).to be true
      end
    end
  end

  describe "#context_help_meta_tag" do
    context "without current_user" do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it "returns empty string" do
        expect(helper.context_help_meta_tag).to eq("")
      end
    end

    context "with current_user" do
      let(:user) { create(:user, :confirmed) }

      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(user).to receive(:tutorial_settings).and_return({ "show_context_help" => true })
      end

      it "returns meta tag" do
        result = helper.context_help_meta_tag

        expect(result).to include("meta")
        expect(result).to include("tutorial-settings")
      end
    end
  end

  describe "#feature_label" do
    it "returns label for known feature" do
      expect(helper.feature_label("submit_entry")).to eq("写真投稿")
    end

    it "returns label for comment feature" do
      expect(helper.feature_label("comment")).to eq("コメント")
    end

    it "returns input for unknown feature" do
      expect(helper.feature_label("unknown_feature")).to eq("unknown_feature")
    end
  end

  describe "#video_tutorial_button" do
    it "returns button with url" do
      result = helper.video_tutorial_button(url: "https://example.com/video", title: "テスト動画")

      expect(result).to include("button")
      expect(result).to include("動画で見る")
      expect(result).to include("https://example.com/video")
    end

    it "returns empty string with blank url" do
      result = helper.video_tutorial_button(url: "", title: "テスト動画")

      expect(result).to eq("")
    end

    it "returns empty string with nil url" do
      result = helper.video_tutorial_button(url: nil, title: "テスト動画")

      expect(result).to eq("")
    end
  end
end
