# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SpotVotes", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:other_user) { create(:user, :confirmed) }
  let(:contest) { create(:contest, :published) }
  let(:certified_spot) { create(:spot, :certified, contest: contest) }
  let(:discovered_spot) { create(:spot, :discovered, contest: contest) }

  describe "POST /spots/:spot_id/spot_vote" do
    context "when not signed in" do
      it "redirects to login page" do
        post spot_spot_vote_path(certified_spot)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in user }

      context "for a certified spot" do
        it "creates a vote" do
          expect {
            post spot_spot_vote_path(certified_spot)
          }.to change(SpotVote, :count).by(1)
        end

        it "redirects back" do
          post spot_spot_vote_path(certified_spot)
          expect(response).to redirect_to(root_path)
        end

        it "responds with turbo_stream when requested" do
          post spot_spot_vote_path(certified_spot),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end

        it "increments votes_count on the spot" do
          expect {
            post spot_spot_vote_path(certified_spot)
          }.to change { certified_spot.reload.votes_count }.by(1)
        end
      end

      context "for an organizer-created spot" do
        let(:organizer_spot) { create(:spot, :organizer_created, contest: contest) }

        it "creates a vote" do
          expect {
            post spot_spot_vote_path(organizer_spot)
          }.to change(SpotVote, :count).by(1)
        end
      end

      context "for a discovered (pending) spot" do
        it "does not create a vote" do
          expect {
            post spot_spot_vote_path(discovered_spot)
          }.not_to change(SpotVote, :count)
        end

        it "redirects with alert" do
          post spot_spot_vote_path(discovered_spot)
          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to be_present
        end
      end

      context "when user has already voted" do
        before { create(:spot_vote, user: user, spot: certified_spot) }

        it "does not create another vote" do
          expect {
            post spot_spot_vote_path(certified_spot)
          }.not_to change(SpotVote, :count)
        end
      end
    end
  end

  describe "DELETE /spots/:spot_id/spot_vote" do
    context "when not signed in" do
      it "redirects to login page" do
        delete spot_spot_vote_path(certified_spot)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in user }

      context "when user has voted" do
        before { create(:spot_vote, user: user, spot: certified_spot) }

        it "removes the vote" do
          expect {
            delete spot_spot_vote_path(certified_spot)
          }.to change(SpotVote, :count).by(-1)
        end

        it "redirects back" do
          delete spot_spot_vote_path(certified_spot)
          expect(response).to redirect_to(root_path)
        end

        it "responds with turbo_stream when requested" do
          delete spot_spot_vote_path(certified_spot),
                 headers: { "Accept" => "text/vnd.turbo-stream.html" }
          expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        end

        it "decrements votes_count on the spot" do
          expect {
            delete spot_spot_vote_path(certified_spot)
          }.to change { certified_spot.reload.votes_count }.by(-1)
        end
      end

      context "when user has not voted" do
        it "does not change vote count" do
          expect {
            delete spot_spot_vote_path(certified_spot)
          }.not_to change(SpotVote, :count)
        end

        it "redirects back" do
          delete spot_spot_vote_path(certified_spot)
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end
end
