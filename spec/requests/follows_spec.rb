# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Follows", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:target_user) { create(:user, :confirmed) }

  describe "POST /users/:user_id/follow" do
    context "when not signed in" do
      it "redirects to login page" do
        post user_follow_path(target_user)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "creates a follow" do
        expect {
          post user_follow_path(target_user)
        }.to change(Follow, :count).by(1)
      end

      it "redirects to user profile with success message" do
        post user_follow_path(target_user)
        expect(response).to redirect_to(user_path(target_user))
        expect(flash[:notice]).to be_present
      end

      it "does not allow following self" do
        expect {
          post user_follow_path(user)
        }.not_to change(Follow, :count)
      end

      it "handles duplicate follow gracefully" do
        create(:follow, follower: user, followed: target_user)
        expect {
          post user_follow_path(target_user)
        }.not_to change(Follow, :count)
      end

      context "with turbo_stream format" do
        it "responds with turbo_stream" do
          post user_follow_path(target_user), as: :turbo_stream
          expect(response.media_type).to eq Mime[:turbo_stream]
        end
      end
    end
  end

  describe "DELETE /users/:user_id/follow" do
    context "when signed in" do
      before do
        sign_in user
        create(:follow, follower: user, followed: target_user)
      end

      it "destroys the follow" do
        expect {
          delete user_follow_path(target_user)
        }.to change(Follow, :count).by(-1)
      end

      it "redirects to user profile" do
        delete user_follow_path(target_user)
        expect(response).to redirect_to(user_path(target_user))
      end

      context "with turbo_stream format" do
        it "responds with turbo_stream" do
          delete user_follow_path(target_user), as: :turbo_stream
          expect(response.media_type).to eq Mime[:turbo_stream]
        end
      end
    end
  end
end
