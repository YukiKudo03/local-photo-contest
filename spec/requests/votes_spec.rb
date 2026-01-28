require 'rails_helper'

RSpec.describe "Votes", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }
  let(:entry_owner) { create(:user, :confirmed) }
  let(:entry) { create(:entry, user: entry_owner, contest: contest) }
  let(:voter) { create(:user, :confirmed) }

  describe "POST /entries/:entry_id/vote" do
    context "when not signed in" do
      it "redirects to login page" do
        post entry_vote_path(entry)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in voter }

      it "creates a vote" do
        expect {
          post entry_vote_path(entry)
        }.to change(Vote, :count).by(1)
      end

      it "redirects to entry page with success message" do
        post entry_vote_path(entry)
        expect(response).to redirect_to(entry_path(entry))
        expect(flash[:notice]).to eq("投票しました。")
      end

      context "when user already voted" do
        before { create(:vote, user: voter, entry: entry) }

        it "does not create duplicate vote" do
          expect {
            post entry_vote_path(entry)
          }.not_to change(Vote, :count)
        end
      end

      context "when voting on own entry" do
        before { sign_in entry_owner }

        it "does not create vote" do
          expect {
            post entry_vote_path(entry)
          }.not_to change(Vote, :count)
        end
      end

      context "when contest is not accepting entries" do
        let(:finished_entry) do
          e = create(:entry, contest: contest)
          contest.update!(status: :finished)
          e
        end

        it "redirects with alert" do
          post entry_vote_path(finished_entry)
          expect(response).to redirect_to(entry_path(finished_entry))
          expect(flash[:alert]).to eq("投票期間が終了しています。")
        end

        it "does not create vote" do
          finished_entry # ensure entry is created before counting
          expect {
            post entry_vote_path(finished_entry)
          }.not_to change(Vote, :count)
        end
      end
    end
  end

  describe "DELETE /entries/:entry_id/vote" do
    context "when not signed in" do
      it "redirects to login page" do
        delete entry_vote_path(entry)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before do
        sign_in voter
        create(:vote, user: voter, entry: entry)
      end

      it "destroys the vote" do
        expect {
          delete entry_vote_path(entry)
        }.to change(Vote, :count).by(-1)
      end

      it "redirects to entry page with success message" do
        delete entry_vote_path(entry)
        expect(response).to redirect_to(entry_path(entry))
        expect(flash[:notice]).to eq("投票を取り消しました。")
      end

      context "when vote does not exist" do
        before { Vote.destroy_all }

        it "does not cause error" do
          expect {
            delete entry_vote_path(entry)
          }.not_to change(Vote, :count)
        end
      end
    end
  end
end
