# frozen_string_literal: true

require "rails_helper"

RSpec.describe "My::ActivityFeed", type: :request do
  let(:user) { create(:user, :confirmed) }

  describe "GET /my/activity_feed" do
    context "when not signed in" do
      it "redirects to login page" do
        get my_activity_feed_index_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "returns successful response" do
        get my_activity_feed_index_path
        expect(response).to have_http_status(:success)
      end

      it "shows empty state when not following anyone" do
        get my_activity_feed_index_path
        expect(response.body).to include(I18n.t("social.activity_feed.empty_no_follows"))
      end

      context "when following other users" do
        let(:followed_user) { create(:user, :confirmed, name: "Photographer A") }
        let(:organizer) { create(:user, :organizer, :confirmed) }
        let(:contest) { create(:contest, :published, user: organizer) }

        before do
          create(:follow, follower: user, followed: followed_user)
        end

        it "shows entries from followed users" do
          create(:entry, user: followed_user, contest: contest, title: "Beautiful Sunset")
          get my_activity_feed_index_path
          expect(response.body).to include("Photographer A")
        end

        it "shows empty activity state when followed users have no activity" do
          get my_activity_feed_index_path
          expect(response.body).to include(I18n.t("social.activity_feed.empty_state"))
        end
      end
    end
  end
end
