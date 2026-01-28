# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers::Contests", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:other_organizer) { create(:user, :organizer, :confirmed) }
  let(:terms) { create(:terms_of_service, :current) }

  before do
    create(:terms_acceptance, user: organizer, terms_of_service: terms)
    create(:terms_acceptance, user: other_organizer, terms_of_service: terms)
  end

  describe "GET /organizers/contests" do
    context "when not authenticated" do
      it "redirects to login" do
        get organizers_contests_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as organizer" do
      before { sign_in organizer }

      it "returns success" do
        get organizers_contests_path
        expect(response).to have_http_status(:success)
      end

      it "shows only own contests" do
        own_contest = create(:contest, user: organizer)
        other_contest = create(:contest, user: other_organizer)

        get organizers_contests_path

        expect(response.body).to include(own_contest.title)
        expect(response.body).not_to include(other_contest.title)
      end

      it "filters by status" do
        draft_contest = create(:contest, :draft, user: organizer)
        published_contest = create(:contest, :published, user: organizer)

        get organizers_contests_path(status: :draft)

        expect(response.body).to include(draft_contest.title)
        expect(response.body).not_to include(published_contest.title)
      end
    end
  end

  describe "GET /organizers/contests/:id" do
    let(:contest) { create(:contest, user: organizer) }

    context "when not authenticated" do
      it "redirects to login" do
        get organizers_contest_path(contest)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as owner" do
      before { sign_in organizer }

      it "returns success" do
        get organizers_contest_path(contest)
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated as non-owner" do
      before { sign_in other_organizer }

      it "redirects with alert" do
        get organizers_contest_path(contest)
        expect(response).to redirect_to(organizers_contests_path)
        expect(flash[:alert]).to eq("この操作を行う権限がありません。")
      end
    end
  end

  describe "GET /organizers/contests/new" do
    context "when authenticated as organizer" do
      before { sign_in organizer }

      it "returns success" do
        get new_organizers_contest_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST /organizers/contests" do
    let(:valid_params) { { contest: { title: "新規コンテスト", theme: "テスト" } } }
    let(:invalid_params) { { contest: { title: "", theme: "テスト" } } }

    context "when authenticated as organizer" do
      before { sign_in organizer }

      context "with valid params" do
        it "creates a new contest" do
          expect {
            post organizers_contests_path, params: valid_params
          }.to change(Contest, :count).by(1)
        end

        it "redirects to the contest page" do
          post organizers_contests_path, params: valid_params
          expect(response).to redirect_to(organizers_contest_path(Contest.last))
        end

        it "sets the current user as owner" do
          post organizers_contests_path, params: valid_params
          expect(Contest.last.user).to eq(organizer)
        end

        it "creates as draft" do
          post organizers_contests_path, params: valid_params
          expect(Contest.last).to be_draft
        end
      end

      context "with invalid params" do
        it "does not create a contest" do
          expect {
            post organizers_contests_path, params: invalid_params
          }.not_to change(Contest, :count)
        end

        it "renders new with unprocessable_entity status" do
          post organizers_contests_path, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "with area_id" do
        let(:area) { create(:area, user: organizer) }

        it "creates a contest with area" do
          post organizers_contests_path, params: { contest: { title: "エリア付きコンテスト", area_id: area.id } }
          expect(Contest.last.area).to eq(area)
        end

        it "creates a contest with require_spot" do
          post organizers_contests_path, params: { contest: { title: "スポット必須コンテスト", area_id: area.id, require_spot: true } }
          expect(Contest.last.require_spot).to be true
        end

        context "when area belongs to other user" do
          let(:other_area) { create(:area, user: other_organizer) }

          it "does not create the contest" do
            expect {
              post organizers_contests_path, params: { contest: { title: "他人のエリア", area_id: other_area.id } }
            }.not_to change(Contest, :count)
          end

          it "renders new with unprocessable_entity" do
            post organizers_contests_path, params: { contest: { title: "他人のエリア", area_id: other_area.id } }
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end

      context "with moderation settings" do
        it "creates a contest with moderation enabled" do
          post organizers_contests_path, params: { contest: { title: "モデレーション有効", moderation_enabled: true } }
          expect(Contest.last.moderation_enabled).to be true
        end

        it "creates a contest with moderation disabled" do
          post organizers_contests_path, params: { contest: { title: "モデレーション無効", moderation_enabled: false } }
          expect(Contest.last.moderation_enabled).to be false
        end

        it "creates a contest with custom moderation threshold" do
          post organizers_contests_path, params: { contest: { title: "閾値設定", moderation_enabled: true, moderation_threshold: 75.0 } }
          expect(Contest.last.moderation_threshold).to eq(75.0)
        end
      end
    end
  end

  describe "GET /organizers/contests/:id/edit" do
    let(:contest) { create(:contest, user: organizer) }

    context "when authenticated as owner" do
      before { sign_in organizer }

      it "returns success" do
        get edit_organizers_contest_path(contest)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "PATCH /organizers/contests/:id" do
    let(:contest) { create(:contest, user: organizer) }
    let(:valid_params) { { contest: { title: "更新されたタイトル" } } }

    context "when authenticated as owner" do
      before { sign_in organizer }

      context "with valid params" do
        it "updates the contest" do
          patch organizers_contest_path(contest), params: valid_params
          expect(contest.reload.title).to eq("更新されたタイトル")
        end

        it "redirects to the contest page" do
          patch organizers_contest_path(contest), params: valid_params
          expect(response).to redirect_to(organizers_contest_path(contest))
        end
      end

      context "with invalid params" do
        it "renders edit with unprocessable_entity status" do
          patch organizers_contest_path(contest), params: { contest: { title: "" } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "with area_id" do
        let(:area) { create(:area, user: organizer) }

        it "updates the contest with area" do
          patch organizers_contest_path(contest), params: { contest: { area_id: area.id } }
          expect(contest.reload.area).to eq(area)
        end

        it "updates the contest with require_spot" do
          patch organizers_contest_path(contest), params: { contest: { area_id: area.id, require_spot: true } }
          expect(contest.reload.require_spot).to be true
        end

        it "clears area when area_id is empty" do
          contest.update!(area: area)
          patch organizers_contest_path(contest), params: { contest: { area_id: "" } }
          expect(contest.reload.area).to be_nil
        end

        context "when area belongs to other user" do
          let(:other_area) { create(:area, user: other_organizer) }

          it "does not update the contest" do
            original_title = contest.title
            patch organizers_contest_path(contest), params: { contest: { area_id: other_area.id } }
            expect(contest.reload.area).not_to eq(other_area)
          end

          it "renders edit with unprocessable_entity" do
            patch organizers_contest_path(contest), params: { contest: { area_id: other_area.id } }
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end

      context "with moderation settings" do
        it "enables moderation" do
          contest.update!(moderation_enabled: false)
          patch organizers_contest_path(contest), params: { contest: { moderation_enabled: true } }
          expect(contest.reload.moderation_enabled).to be true
        end

        it "disables moderation" do
          contest.update!(moderation_enabled: true)
          patch organizers_contest_path(contest), params: { contest: { moderation_enabled: false } }
          expect(contest.reload.moderation_enabled).to be false
        end

        it "updates moderation threshold" do
          patch organizers_contest_path(contest), params: { contest: { moderation_threshold: 80.0 } }
          expect(contest.reload.moderation_threshold).to eq(80.0)
        end

        it "updates both moderation settings at once" do
          patch organizers_contest_path(contest), params: {
            contest: { moderation_enabled: true, moderation_threshold: 55.0 }
          }
          contest.reload
          expect(contest.moderation_enabled).to be true
          expect(contest.moderation_threshold).to eq(55.0)
        end
      end
    end
  end

  describe "DELETE /organizers/contests/:id" do
    context "when authenticated as owner" do
      before { sign_in organizer }

      context "when contest is draft" do
        let!(:contest) { create(:contest, :draft, user: organizer) }

        it "soft deletes the contest" do
          delete organizers_contest_path(contest)
          expect(contest.reload.deleted_at).not_to be_nil
        end

        it "redirects to index" do
          delete organizers_contest_path(contest)
          expect(response).to redirect_to(organizers_contests_path)
        end
      end

      context "when contest is published" do
        let!(:contest) { create(:contest, :published, user: organizer) }

        it "does not delete the contest" do
          delete organizers_contest_path(contest)
          expect(contest.reload.deleted_at).to be_nil
        end

        it "redirects with alert" do
          delete organizers_contest_path(contest)
          expect(response).to redirect_to(organizers_contest_path(contest))
          expect(flash[:alert]).to be_present
        end
      end
    end
  end

  describe "PATCH /organizers/contests/:id/publish" do
    context "when authenticated as owner" do
      before { sign_in organizer }

      context "when contest is draft" do
        let(:contest) { create(:contest, :draft, user: organizer) }

        it "publishes the contest" do
          patch publish_organizers_contest_path(contest)
          expect(contest.reload).to be_published
        end

        it "redirects with notice" do
          patch publish_organizers_contest_path(contest)
          expect(response).to redirect_to(organizers_contest_path(contest))
          expect(flash[:notice]).to eq("コンテストを公開しました。")
        end
      end

      context "when contest is already published" do
        let(:contest) { create(:contest, :published, user: organizer) }

        it "redirects with alert" do
          patch publish_organizers_contest_path(contest)
          expect(response).to redirect_to(organizers_contest_path(contest))
          expect(flash[:alert]).to be_present
        end
      end
    end
  end

  describe "PATCH /organizers/contests/:id/finish" do
    context "when authenticated as owner" do
      before { sign_in organizer }

      context "when contest is published" do
        let(:contest) { create(:contest, :published, user: organizer) }

        it "finishes the contest" do
          patch finish_organizers_contest_path(contest)
          expect(contest.reload).to be_finished
        end

        it "redirects with notice" do
          patch finish_organizers_contest_path(contest)
          expect(response).to redirect_to(organizers_contest_path(contest))
          expect(flash[:notice]).to eq("コンテストを終了しました。")
        end
      end

      context "when contest is draft" do
        let(:contest) { create(:contest, :draft, user: organizer) }

        it "redirects with alert" do
          patch finish_organizers_contest_path(contest)
          expect(response).to redirect_to(organizers_contest_path(contest))
          expect(flash[:alert]).to be_present
        end
      end
    end
  end

  describe "PATCH /organizers/contests/:id/announce_results" do
    context "when authenticated as owner" do
      before { sign_in organizer }

      context "when contest is finished" do
        let(:contest) { create(:contest, :finished, user: organizer) }

        it "announces results" do
          patch announce_results_organizers_contest_path(contest)
          expect(contest.reload.results_announced_at).not_to be_nil
        end

        it "redirects with notice" do
          patch announce_results_organizers_contest_path(contest)
          expect(response).to redirect_to(organizers_contest_path(contest))
          expect(flash[:notice]).to eq("結果を発表しました。")
        end
      end

      context "when contest is published (not finished)" do
        let(:contest) { create(:contest, :published, user: organizer) }

        it "redirects with alert" do
          patch announce_results_organizers_contest_path(contest)
          expect(response).to redirect_to(organizers_contest_path(contest))
          expect(flash[:alert]).to be_present
        end
      end

      context "when results already announced" do
        let(:contest) { create(:contest, :finished, user: organizer, results_announced_at: 1.day.ago) }

        it "redirects with alert" do
          patch announce_results_organizers_contest_path(contest)
          expect(response).to redirect_to(organizers_contest_path(contest))
          expect(flash[:alert]).to be_present
        end
      end
    end

    context "when authenticated as non-owner" do
      let(:contest) { create(:contest, :finished, user: organizer) }

      before { sign_in other_organizer }

      it "redirects with alert" do
        patch announce_results_organizers_contest_path(contest)
        expect(response).to redirect_to(organizers_contests_path)
        expect(flash[:alert]).to eq("この操作を行う権限がありません。")
      end
    end
  end
end
