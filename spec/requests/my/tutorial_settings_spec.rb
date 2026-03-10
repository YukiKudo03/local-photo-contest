# frozen_string_literal: true

require "rails_helper"

RSpec.describe "My::TutorialSettings", type: :request do
  let(:user) { create(:user, :participant, :confirmed) }

  before do
    sign_in user
  end

  describe "GET /my/tutorial_settings" do
    it "returns success" do
      get my_tutorial_settings_path
      expect(response).to have_http_status(:success)
    end

    it "displays tutorial settings page" do
      get my_tutorial_settings_path
      expect(response.body).to include("チュートリアル設定")
      expect(response.body).to include("表示設定")
      expect(response.body).to include("チュートリアル進捗")
    end

    it "shows available tutorials for participant" do
      get my_tutorial_settings_path
      expect(response.body).to include("参加者向けガイド")
      expect(response.body).to include("写真投稿")
      expect(response.body).to include("投票")
    end

    context "when user is organizer" do
      let(:user) { create(:user, :organizer, :confirmed) }

      it "shows organizer-specific tutorials" do
        get my_tutorial_settings_path
        expect(response.body).to include("運営者向けガイド")
        expect(response.body).to include("コンテスト作成")
        expect(response.body).to include("エリア管理")
      end
    end

    context "when user is not authenticated" do
      before { sign_out user }

      it "redirects to login" do
        get my_tutorial_settings_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /my/tutorial_settings" do
    it "updates tutorial settings" do
      patch my_tutorial_settings_path, params: {
        tutorial_settings: {
          show_tutorials: "false",
          show_context_help: "true",
          reduced_motion: "true"
        }
      }

      expect(response).to redirect_to(my_tutorial_settings_path)
      user.reload
      expect(user.tutorial_enabled?).to be false
      expect(user.context_help_enabled?).to be true
      expect(user.reduced_motion?).to be true
    end

    it "displays success message" do
      patch my_tutorial_settings_path, params: {
        tutorial_settings: { show_tutorials: "true" }
      }

      follow_redirect!
      expect(response.body).to include("チュートリアル設定を更新しました")
    end

    context "when update fails" do
      before do
        allow_any_instance_of(User).to receive(:update_tutorial_settings).and_return(false)
      end

      it "renders show with error" do
        patch my_tutorial_settings_path, params: {
          tutorial_settings: { show_tutorials: "false" }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when user is not authenticated" do
      before { sign_out user }

      it "redirects to login" do
        patch my_tutorial_settings_path, params: {
          tutorial_settings: { show_tutorials: "false" }
        }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
