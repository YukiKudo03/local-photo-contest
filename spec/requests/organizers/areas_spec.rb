# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers::Areas", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:other_organizer) { create(:user, :organizer, :confirmed) }
  let(:terms) { create(:terms_of_service, :current) }

  before do
    create(:terms_acceptance, user: organizer, terms_of_service: terms)
    create(:terms_acceptance, user: other_organizer, terms_of_service: terms)
  end

  describe "GET /organizers/areas" do
    context "when not authenticated" do
      it "redirects to login" do
        get organizers_areas_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as organizer" do
      before { sign_in organizer }

      it "returns success" do
        get organizers_areas_path
        expect(response).to have_http_status(:success)
      end

      it "shows only own areas" do
        own_area = create(:area, user: organizer)
        other_area = create(:area, user: other_organizer)

        get organizers_areas_path

        expect(response.body).to include(own_area.name)
        expect(response.body).not_to include(other_area.name)
      end
    end
  end

  describe "GET /organizers/areas/:id" do
    let(:area) { create(:area, user: organizer) }

    context "when not authenticated" do
      it "redirects to login" do
        get organizers_area_path(area)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as owner" do
      before { sign_in organizer }

      it "returns success" do
        get organizers_area_path(area)
        expect(response).to have_http_status(:success)
      end

      it "displays area details" do
        get organizers_area_path(area)
        expect(response.body).to include(area.name)
      end
    end

    context "when authenticated as non-owner" do
      before { sign_in other_organizer }

      it "redirects with alert" do
        get organizers_area_path(area)
        expect(response).to redirect_to(organizers_areas_path)
        expect(flash[:alert]).to eq("この操作を行う権限がありません。")
      end
    end
  end

  describe "GET /organizers/areas/new" do
    context "when authenticated as organizer" do
      before { sign_in organizer }

      it "returns success" do
        get new_organizers_area_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /organizers/areas" do
    let(:valid_params) do
      {
        area: {
          name: "テストエリア",
          prefecture: "東京都",
          city: "渋谷区",
          address: "道玄坂1-1-1",
          description: "テスト説明"
        }
      }
    end
    let(:invalid_params) { { area: { name: "" } } }

    context "when authenticated as organizer" do
      before { sign_in organizer }

      context "with valid params" do
        it "creates a new area" do
          expect {
            post organizers_areas_path, params: valid_params
          }.to change(Area, :count).by(1)
        end

        it "redirects to the area page" do
          post organizers_areas_path, params: valid_params
          expect(response).to redirect_to(organizers_area_path(Area.last))
        end

        it "sets the current user as owner" do
          post organizers_areas_path, params: valid_params
          expect(Area.last.user).to eq(organizer)
        end

        it "shows success flash message" do
          post organizers_areas_path, params: valid_params
          expect(flash[:notice]).to eq("エリアを作成しました。")
        end
      end

      context "with invalid params" do
        it "does not create an area" do
          expect {
            post organizers_areas_path, params: invalid_params
          }.not_to change(Area, :count)
        end

        it "renders new with unprocessable_entity status" do
          post organizers_areas_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "with coordinates" do
        let(:params_with_coordinates) do
          valid_params.deep_merge(area: { latitude: 35.6580339, longitude: 139.7016358 })
        end

        it "saves the coordinates" do
          post organizers_areas_path, params: params_with_coordinates
          area = Area.last
          expect(area.latitude).to eq(35.6580339)
          expect(area.longitude).to eq(139.7016358)
        end
      end
    end
  end

  describe "GET /organizers/areas/:id/edit" do
    let(:area) { create(:area, user: organizer) }

    context "when authenticated as owner" do
      before { sign_in organizer }

      it "returns success" do
        get edit_organizers_area_path(area)
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated as non-owner" do
      before { sign_in other_organizer }

      it "redirects with alert" do
        get edit_organizers_area_path(area)
        expect(response).to redirect_to(organizers_areas_path)
        expect(flash[:alert]).to eq("この操作を行う権限がありません。")
      end
    end
  end

  describe "PATCH /organizers/areas/:id" do
    let(:area) { create(:area, user: organizer) }
    let(:valid_params) { { area: { name: "更新されたエリア名" } } }

    context "when authenticated as owner" do
      before { sign_in organizer }

      context "with valid params" do
        it "updates the area" do
          patch organizers_area_path(area), params: valid_params
          expect(area.reload.name).to eq("更新されたエリア名")
        end

        it "redirects to the area page" do
          patch organizers_area_path(area), params: valid_params
          expect(response).to redirect_to(organizers_area_path(area))
        end

        it "shows success flash message" do
          patch organizers_area_path(area), params: valid_params
          expect(flash[:notice]).to eq("エリアを更新しました。")
        end
      end

      context "with invalid params" do
        it "renders edit with unprocessable_entity status" do
          patch organizers_area_path(area), params: { area: { name: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when authenticated as non-owner" do
      before { sign_in other_organizer }

      it "redirects with alert" do
        patch organizers_area_path(area), params: valid_params
        expect(response).to redirect_to(organizers_areas_path)
        expect(flash[:alert]).to eq("この操作を行う権限がありません。")
      end
    end
  end

  describe "DELETE /organizers/areas/:id" do
    context "when authenticated as owner" do
      before { sign_in organizer }

      context "when area has no contests" do
        let!(:area) { create(:area, user: organizer) }

        it "deletes the area" do
          expect {
            delete organizers_area_path(area)
          }.to change(Area, :count).by(-1)
        end

        it "redirects to index" do
          delete organizers_area_path(area)
          expect(response).to redirect_to(organizers_areas_path)
        end

        it "shows success flash message" do
          delete organizers_area_path(area)
          expect(flash[:notice]).to eq("エリアを削除しました。")
        end
      end

      context "when area has contests" do
        let!(:area) { create(:area, user: organizer) }
        let!(:contest) { create(:contest, user: organizer, area: area) }

        it "does not delete the area" do
          expect {
            delete organizers_area_path(area)
          }.not_to change(Area, :count)
        end

        it "redirects with alert" do
          delete organizers_area_path(area)
          expect(response).to redirect_to(organizers_area_path(area))
          expect(flash[:alert]).to eq("このエリアに関連するコンテストがあるため削除できません。")
        end
      end
    end

    context "when authenticated as non-owner" do
      let!(:area) { create(:area, user: organizer) }

      before { sign_in other_organizer }

      it "redirects with alert" do
        delete organizers_area_path(area)
        expect(response).to redirect_to(organizers_areas_path)
        expect(flash[:alert]).to eq("この操作を行う権限がありません。")
      end
    end
  end
end
