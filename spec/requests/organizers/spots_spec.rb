# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers::Spots", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:other_organizer) { create(:user, :organizer, :confirmed) }
  let(:terms) { create(:terms_of_service, :current) }
  let(:contest) { create(:contest, :published, user: organizer) }

  before do
    create(:terms_acceptance, user: organizer, terms_of_service: terms)
    create(:terms_acceptance, user: other_organizer, terms_of_service: terms)
  end

  describe "GET /organizers/contests/:contest_id/spots" do
    context "when not authenticated" do
      it "redirects to login" do
        get organizers_contest_spots_path(contest)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "returns success" do
        get organizers_contest_spots_path(contest)
        expect(response).to have_http_status(:success)
      end

      it "lists all spots" do
        spot = create(:spot, contest: contest, name: "テストスポット")

        get organizers_contest_spots_path(contest)

        expect(response.body).to include("テストスポット")
      end
    end

    context "when authenticated as non-owner" do
      before { sign_in other_organizer }

      it "redirects with alert" do
        get organizers_contest_spots_path(contest)
        expect(response).to redirect_to(organizers_contests_path)
        expect(flash[:alert]).to eq("この操作を行う権限がありません。")
      end
    end
  end

  describe "GET /organizers/contests/:contest_id/spots/new" do
    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "returns success" do
        get new_organizers_contest_spot_path(contest)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /organizers/contests/:contest_id/spots" do
    let(:valid_params) do
      {
        spot: {
          name: "渋谷商店",
          category: "restaurant",
          address: "東京都渋谷区道玄坂1-1-1",
          description: "人気のラーメン店",
          latitude: 35.6580339,
          longitude: 139.7016358
        }
      }
    end
    let(:invalid_params) { { spot: { name: "" } } }

    context "when authenticated as contest owner" do
      before { sign_in organizer }

      context "with valid params" do
        it "creates a new spot" do
          expect {
            post organizers_contest_spots_path(contest), params: valid_params
          }.to change(Spot, :count).by(1)
        end

        it "redirects to spots index" do
          post organizers_contest_spots_path(contest), params: valid_params
          expect(response).to redirect_to(organizers_contest_spots_path(contest))
        end

        it "shows success flash message" do
          post organizers_contest_spots_path(contest), params: valid_params
          expect(flash[:notice]).to eq("スポットを作成しました。")
        end

        it "associates spot with contest" do
          post organizers_contest_spots_path(contest), params: valid_params
          expect(Spot.last.contest).to eq(contest)
        end

        it "saves the coordinates" do
          post organizers_contest_spots_path(contest), params: valid_params
          spot = Spot.last
          expect(spot.latitude).to eq(35.6580339)
          expect(spot.longitude).to eq(139.7016358)
        end
      end

      context "with invalid params" do
        it "does not create a spot" do
          expect {
            post organizers_contest_spots_path(contest), params: invalid_params
          }.not_to change(Spot, :count)
        end

        it "renders new with unprocessable_entity" do
          post organizers_contest_spots_path(contest), params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when authenticated as non-owner" do
      before { sign_in other_organizer }

      it "redirects with alert" do
        post organizers_contest_spots_path(contest), params: valid_params
        expect(response).to redirect_to(organizers_contests_path)
        expect(flash[:alert]).to eq("この操作を行う権限がありません。")
      end
    end
  end

  describe "GET /organizers/contests/:contest_id/spots/:id/edit" do
    let!(:spot) { create(:spot, contest: contest) }

    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "returns success" do
        get edit_organizers_contest_spot_path(contest, spot)
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated as non-owner" do
      before { sign_in other_organizer }

      it "redirects with alert" do
        get edit_organizers_contest_spot_path(contest, spot)
        expect(response).to redirect_to(organizers_contests_path)
        expect(flash[:alert]).to eq("この操作を行う権限がありません。")
      end
    end
  end

  describe "PATCH /organizers/contests/:contest_id/spots/:id" do
    let!(:spot) { create(:spot, contest: contest, name: "旧スポット名") }
    let(:valid_params) { { spot: { name: "新スポット名" } } }

    context "when authenticated as contest owner" do
      before { sign_in organizer }

      context "with valid params" do
        it "updates the spot" do
          patch organizers_contest_spot_path(contest, spot), params: valid_params
          expect(spot.reload.name).to eq("新スポット名")
        end

        it "redirects to spots index" do
          patch organizers_contest_spot_path(contest, spot), params: valid_params
          expect(response).to redirect_to(organizers_contest_spots_path(contest))
        end

        it "shows success flash message" do
          patch organizers_contest_spot_path(contest, spot), params: valid_params
          expect(flash[:notice]).to eq("スポットを更新しました。")
        end
      end

      context "with invalid params" do
        it "renders edit with unprocessable_entity" do
          patch organizers_contest_spot_path(contest, spot),
                params: { spot: { name: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when authenticated as non-owner" do
      before { sign_in other_organizer }

      it "does not update the spot" do
        patch organizers_contest_spot_path(contest, spot), params: valid_params
        expect(spot.reload.name).to eq("旧スポット名")
      end

      it "redirects with alert" do
        patch organizers_contest_spot_path(contest, spot), params: valid_params
        expect(response).to redirect_to(organizers_contests_path)
        expect(flash[:alert]).to eq("この操作を行う権限がありません。")
      end
    end
  end

  describe "DELETE /organizers/contests/:contest_id/spots/:id" do
    context "when authenticated as contest owner" do
      before { sign_in organizer }

      context "when spot has no entries" do
        let!(:spot) { create(:spot, contest: contest) }

        it "deletes the spot" do
          expect {
            delete organizers_contest_spot_path(contest, spot)
          }.to change(Spot, :count).by(-1)
        end

        it "redirects to spots index" do
          delete organizers_contest_spot_path(contest, spot)
          expect(response).to redirect_to(organizers_contest_spots_path(contest))
        end

        it "shows success flash message" do
          delete organizers_contest_spot_path(contest, spot)
          expect(flash[:notice]).to eq("スポットを削除しました。")
        end
      end

      context "when spot has entries" do
        let!(:spot) { create(:spot, contest: contest) }
        let!(:entry) { create(:entry, contest: contest, spot: spot) }

        it "deletes the spot" do
          expect {
            delete organizers_contest_spot_path(contest, spot)
          }.to change(Spot, :count).by(-1)
        end

        it "nullifies entry spot association" do
          delete organizers_contest_spot_path(contest, spot)
          expect(entry.reload.spot_id).to be_nil
        end
      end
    end

    context "when authenticated as non-owner" do
      let!(:spot) { create(:spot, contest: contest) }

      before { sign_in other_organizer }

      it "does not delete the spot" do
        expect {
          delete organizers_contest_spot_path(contest, spot)
        }.not_to change(Spot, :count)
      end

      it "redirects with alert" do
        delete organizers_contest_spot_path(contest, spot)
        expect(response).to redirect_to(organizers_contests_path)
        expect(flash[:alert]).to eq("この操作を行う権限がありません。")
      end
    end
  end

  describe "POST /organizers/contests/:contest_id/spots/:id/merge (do_merge)" do
    let!(:spot) { create(:spot, contest: contest) }
    let!(:primary_spot) { create(:spot, contest: contest) }

    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "redirects with alert when merge fails" do
        allow_any_instance_of(SpotMergeService).to receive(:merge).and_raise(SpotMergeService::MergeError, "merge failed")

        post merge_organizers_contest_spot_path(contest, spot),
             params: { primary_spot_id: primary_spot.id }

        expect(response).to redirect_to(merge_organizers_contest_spot_path(contest, spot))
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "PATCH /organizers/contests/:contest_id/spots/update_positions - error handling" do
    let!(:spot1) { create(:spot, contest: contest, position: 1) }

    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "returns 422 when position update fails" do
        allow_any_instance_of(Spot).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(spot1))

        patch update_positions_organizers_contest_spots_path(contest),
              params: { positions: [ spot1.id ] }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /organizers/contests/:contest_id/spots/update_positions" do
    let!(:spot1) { create(:spot, contest: contest, position: 1) }
    let!(:spot2) { create(:spot, contest: contest, position: 2) }
    let!(:spot3) { create(:spot, contest: contest, position: 3) }

    context "when authenticated as contest owner" do
      before { sign_in organizer }

      it "updates spot positions" do
        patch update_positions_organizers_contest_spots_path(contest),
              params: { positions: [ spot3.id, spot1.id, spot2.id ] }

        expect(spot3.reload.position).to eq(1)
        expect(spot1.reload.position).to eq(2)
        expect(spot2.reload.position).to eq(3)
      end

      it "returns ok status" do
        patch update_positions_organizers_contest_spots_path(contest),
              params: { positions: [ spot3.id, spot1.id, spot2.id ] }
        expect(response).to have_http_status(:ok)
      end
    end

    context "when authenticated as non-owner" do
      before { sign_in other_organizer }

      it "redirects with alert" do
        patch update_positions_organizers_contest_spots_path(contest),
              params: { positions: [ spot3.id, spot1.id, spot2.id ] }
        expect(response).to redirect_to(organizers_contests_path)
        expect(flash[:alert]).to eq("この操作を行う権限がありません。")
      end
    end
  end
end
