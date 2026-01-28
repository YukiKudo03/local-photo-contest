# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers::DiscoverySpots", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:other_organizer) { create(:user, :organizer, :confirmed) }
  let(:regular_user) { create(:user, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }
  let(:other_contest) { create(:contest, :published, user: other_organizer) }

  describe "GET /organizers/contests/:contest_id/discovery_spots" do
    context "when not signed in" do
      it "redirects to login page" do
        get organizers_contest_discovery_spots_path(contest)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as regular user" do
      before { sign_in regular_user }

      it "returns forbidden" do
        get organizers_contest_discovery_spots_path(contest)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when signed in as organizer" do
      before { sign_in organizer }

      it "returns success for own contest" do
        get organizers_contest_discovery_spots_path(contest)
        expect(response).to have_http_status(:success)
      end

      it "redirects when accessing other organizer's contest" do
        get organizers_contest_discovery_spots_path(other_contest)
        expect(response).to redirect_to(organizers_contests_path)
      end

      it "displays pending certification spots" do
        pending_spot = create(:spot, :discovered, contest: contest, name: "発掘スポット")
        certified_spot = create(:spot, :certified, contest: contest, name: "認定スポット")

        get organizers_contest_discovery_spots_path(contest)

        expect(response.body).to include("発掘スポット")
        expect(response.body).to include("認定スポット") # shown in certified tab
      end
    end
  end

  describe "PATCH /organizers/contests/:contest_id/discovery_spots/:id/certify" do
    let!(:spot) { create(:spot, :discovered, contest: contest) }

    context "when not signed in" do
      it "redirects to login page" do
        patch certify_organizers_contest_discovery_spot_path(contest, spot)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as organizer" do
      before { sign_in organizer }

      it "certifies the spot" do
        patch certify_organizers_contest_discovery_spot_path(contest, spot)
        expect(spot.reload.discovery_certified?).to be true
      end

      it "sets certified_by to current user" do
        patch certify_organizers_contest_discovery_spot_path(contest, spot)
        expect(spot.reload.certified_by).to eq(organizer)
      end

      it "redirects back to discovery spots index" do
        patch certify_organizers_contest_discovery_spot_path(contest, spot)
        expect(response).to redirect_to(organizers_contest_discovery_spots_path(contest))
      end

      it "responds with turbo_stream when requested" do
        patch certify_organizers_contest_discovery_spot_path(contest, spot),
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "returns not found for spot from other contest" do
        other_spot = create(:spot, :discovered, contest: other_contest)
        patch certify_organizers_contest_discovery_spot_path(contest, other_spot)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /organizers/contests/:contest_id/discovery_spots/:id/reject" do
    let!(:spot) { create(:spot, :discovered, contest: contest) }
    let(:rejection_reason) { "不適切なスポットです" }

    context "when not signed in" do
      it "redirects to login page" do
        patch reject_organizers_contest_discovery_spot_path(contest, spot),
              params: { reason: rejection_reason }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as organizer" do
      before { sign_in organizer }

      it "rejects the spot with reason" do
        patch reject_organizers_contest_discovery_spot_path(contest, spot),
              params: { reason: rejection_reason }
        expect(spot.reload.discovery_rejected?).to be true
        expect(spot.rejection_reason).to eq(rejection_reason)
      end

      it "redirects back to discovery spots index" do
        patch reject_organizers_contest_discovery_spot_path(contest, spot),
              params: { reason: rejection_reason }
        expect(response).to redirect_to(organizers_contest_discovery_spots_path(contest))
      end

      it "responds with turbo_stream when requested" do
        patch reject_organizers_contest_discovery_spot_path(contest, spot),
              params: { reason: rejection_reason },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "requires rejection reason" do
        patch reject_organizers_contest_discovery_spot_path(contest, spot),
              params: { reason: "" }
        expect(response).to redirect_to(organizers_contest_discovery_spots_path(contest))
        expect(flash[:alert]).to be_present
      end

      it "returns not found for spot from other contest" do
        other_spot = create(:spot, :discovered, contest: other_contest)
        patch reject_organizers_contest_discovery_spot_path(contest, other_spot),
              params: { reason: rejection_reason }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
