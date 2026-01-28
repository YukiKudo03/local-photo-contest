# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers::DiscoveryChallenges", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:other_organizer) { create(:user, :organizer, :confirmed) }
  let(:regular_user) { create(:user, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }
  let(:other_contest) { create(:contest, :published, user: other_organizer) }

  describe "GET /organizers/contests/:contest_id/discovery_challenges" do
    context "when not signed in" do
      it "redirects to login page" do
        get organizers_contest_discovery_challenges_path(contest)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as regular user" do
      before { sign_in regular_user }

      it "returns forbidden" do
        get organizers_contest_discovery_challenges_path(contest)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when signed in as organizer" do
      before { sign_in organizer }

      it "returns success for own contest" do
        get organizers_contest_discovery_challenges_path(contest)
        expect(response).to have_http_status(:success)
      end

      it "redirects when accessing other organizer's contest" do
        get organizers_contest_discovery_challenges_path(other_contest)
        expect(response).to redirect_to(organizers_contests_path)
      end

      it "displays challenges" do
        challenge = create(:discovery_challenge, :draft, contest: contest, name: "テストチャレンジ")

        get organizers_contest_discovery_challenges_path(contest)

        expect(response.body).to include("テストチャレンジ")
      end
    end
  end

  describe "GET /organizers/contests/:contest_id/discovery_challenges/new" do
    context "when signed in as organizer" do
      before { sign_in organizer }

      it "returns success" do
        get new_organizers_contest_discovery_challenge_path(contest)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /organizers/contests/:contest_id/discovery_challenges" do
    let(:valid_params) do
      {
        discovery_challenge: {
          name: "新しいチャレンジ",
          theme: "街角の風景",
          description: "チャレンジの説明",
          starts_at: 1.day.from_now,
          ends_at: 1.week.from_now
        }
      }
    end

    context "when not signed in" do
      it "redirects to login page" do
        post organizers_contest_discovery_challenges_path(contest), params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as organizer" do
      before { sign_in organizer }

      it "creates a new challenge" do
        expect {
          post organizers_contest_discovery_challenges_path(contest), params: valid_params
        }.to change(DiscoveryChallenge, :count).by(1)
      end

      it "redirects to challenges index after creation" do
        post organizers_contest_discovery_challenges_path(contest), params: valid_params
        expect(response).to redirect_to(organizers_contest_discovery_challenges_path(contest))
      end

      it "sets the contest association" do
        post organizers_contest_discovery_challenges_path(contest), params: valid_params
        expect(DiscoveryChallenge.last.contest).to eq(contest)
      end

      it "sets default status to draft" do
        post organizers_contest_discovery_challenges_path(contest), params: valid_params
        expect(DiscoveryChallenge.last.challenge_draft?).to be true
      end
    end
  end

  describe "GET /organizers/contests/:contest_id/discovery_challenges/:id/edit" do
    let!(:challenge) { create(:discovery_challenge, :draft, contest: contest) }

    context "when signed in as organizer" do
      before { sign_in organizer }

      it "returns success" do
        get edit_organizers_contest_discovery_challenge_path(contest, challenge)
        expect(response).to have_http_status(:success)
      end

      it "returns not found for challenge from other contest" do
        other_challenge = create(:discovery_challenge, contest: other_contest)
        get edit_organizers_contest_discovery_challenge_path(contest, other_challenge)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /organizers/contests/:contest_id/discovery_challenges/:id" do
    let!(:challenge) { create(:discovery_challenge, :draft, contest: contest, name: "元の名前") }

    context "when signed in as organizer" do
      before { sign_in organizer }

      it "updates the challenge" do
        patch organizers_contest_discovery_challenge_path(contest, challenge),
              params: { discovery_challenge: { name: "更新後の名前" } }
        expect(challenge.reload.name).to eq("更新後の名前")
      end

      it "redirects to challenges index after update" do
        patch organizers_contest_discovery_challenge_path(contest, challenge),
              params: { discovery_challenge: { name: "更新後の名前" } }
        expect(response).to redirect_to(organizers_contest_discovery_challenges_path(contest))
      end
    end
  end

  describe "DELETE /organizers/contests/:contest_id/discovery_challenges/:id" do
    let!(:challenge) { create(:discovery_challenge, :draft, contest: contest) }

    context "when signed in as organizer" do
      before { sign_in organizer }

      it "deletes the challenge" do
        expect {
          delete organizers_contest_discovery_challenge_path(contest, challenge)
        }.to change(DiscoveryChallenge, :count).by(-1)
      end

      it "redirects to challenges index after deletion" do
        delete organizers_contest_discovery_challenge_path(contest, challenge)
        expect(response).to redirect_to(organizers_contest_discovery_challenges_path(contest))
      end
    end
  end

  describe "PATCH /organizers/contests/:contest_id/discovery_challenges/:id/activate" do
    let!(:challenge) { create(:discovery_challenge, :draft, contest: contest) }

    context "when signed in as organizer" do
      before { sign_in organizer }

      it "activates the challenge" do
        patch activate_organizers_contest_discovery_challenge_path(contest, challenge)
        expect(challenge.reload.challenge_active?).to be true
      end

      it "redirects to challenges index" do
        patch activate_organizers_contest_discovery_challenge_path(contest, challenge)
        expect(response).to redirect_to(organizers_contest_discovery_challenges_path(contest))
      end

      it "cannot activate an already active challenge" do
        challenge.challenge_active!
        patch activate_organizers_contest_discovery_challenge_path(contest, challenge)
        expect(response).to redirect_to(organizers_contest_discovery_challenges_path(contest))
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "PATCH /organizers/contests/:contest_id/discovery_challenges/:id/finish" do
    let!(:challenge) { create(:discovery_challenge, :active, contest: contest) }

    context "when signed in as organizer" do
      before { sign_in organizer }

      it "finishes the challenge" do
        patch finish_organizers_contest_discovery_challenge_path(contest, challenge)
        expect(challenge.reload.challenge_finished?).to be true
      end

      it "redirects to challenges index" do
        patch finish_organizers_contest_discovery_challenge_path(contest, challenge)
        expect(response).to redirect_to(organizers_contest_discovery_challenges_path(contest))
      end

      it "cannot finish a draft challenge" do
        draft_challenge = create(:discovery_challenge, :draft, contest: contest)
        patch finish_organizers_contest_discovery_challenge_path(contest, draft_challenge)
        expect(response).to redirect_to(organizers_contest_discovery_challenges_path(contest))
        expect(flash[:alert]).to be_present
      end
    end
  end
end
