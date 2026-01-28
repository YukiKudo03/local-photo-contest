# frozen_string_literal: true

require "rails_helper"

RSpec.describe "My::Profile", type: :request do
  let(:user) { create(:user, :confirmed) }

  describe "GET /my/profile" do
    context "when not authenticated" do
      it "redirects to login page" do
        get my_profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "returns successful response" do
        get my_profile_path
        expect(response).to have_http_status(:success)
      end

      it "displays user email" do
        get my_profile_path
        expect(response.body).to include(user.email)
      end

      it "displays user display name" do
        user.update!(name: "Test User")
        get my_profile_path
        expect(response.body).to include("Test User")
      end

      it "displays user bio when present" do
        user.update!(bio: "This is my bio")
        get my_profile_path
        expect(response.body).to include("This is my bio")
      end

      it "displays placeholder when bio is not set" do
        get my_profile_path
        expect(response.body).to include("自己紹介が設定されていません")
      end

      it "displays entry count" do
        contest = create(:contest, :published)
        create(:entry, user: user, contest: contest)
        get my_profile_path
        expect(response.body).to include("1")
      end
    end
  end

  describe "GET /my/profile/edit" do
    context "when not authenticated" do
      it "redirects to login page" do
        get edit_my_profile_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "returns successful response" do
        get edit_my_profile_path
        expect(response).to have_http_status(:success)
      end

      it "displays form with current values" do
        user.update!(name: "Current Name", bio: "Current Bio")
        get edit_my_profile_path
        expect(response.body).to include("Current Name")
        expect(response.body).to include("Current Bio")
      end
    end
  end

  describe "PATCH /my/profile" do
    context "when not authenticated" do
      it "redirects to login page" do
        patch my_profile_path, params: { user: { name: "New Name" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated" do
      before { sign_in user }

      it "updates name successfully" do
        patch my_profile_path, params: { user: { name: "Updated Name" } }
        expect(response).to redirect_to(my_profile_path)
        expect(user.reload.name).to eq("Updated Name")
      end

      it "updates bio successfully" do
        patch my_profile_path, params: { user: { bio: "Updated bio content" } }
        expect(response).to redirect_to(my_profile_path)
        expect(user.reload.bio).to eq("Updated bio content")
      end

      it "displays success notice after update" do
        patch my_profile_path, params: { user: { name: "New Name" } }
        expect(flash[:notice]).to eq("プロフィールを更新しました。")
      end

      it "clears name when empty string is provided" do
        user.update!(name: "Old Name")
        patch my_profile_path, params: { user: { name: "" } }
        expect(user.reload.name).to be_blank
      end

      context "with invalid params" do
        it "rejects name longer than 50 characters" do
          patch my_profile_path, params: { user: { name: "a" * 51 } }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(user.reload.name).not_to eq("a" * 51)
        end

        it "rejects bio longer than 500 characters" do
          patch my_profile_path, params: { user: { bio: "a" * 501 } }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(user.reload.bio).not_to eq("a" * 501)
        end
      end

      context "with avatar upload" do
        let(:valid_image) { fixture_file_upload("spec/fixtures/files/test_image.jpg", "image/jpeg") }

        it "uploads avatar successfully" do
          patch my_profile_path, params: { user: { avatar: valid_image } }
          expect(response).to redirect_to(my_profile_path)
          expect(user.reload.avatar).to be_attached
        end
      end
    end
  end
end
