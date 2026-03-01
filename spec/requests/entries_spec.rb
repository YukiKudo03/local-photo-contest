require 'rails_helper'

RSpec.describe "Entries", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:other_user) { create(:user, :confirmed) }
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }

  describe "GET /contests/:contest_id/entries/new" do
    context "when not signed in" do
      it "redirects to login page" do
        get new_contest_entry_path(contest)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "returns success" do
        get new_contest_entry_path(contest)
        expect(response).to have_http_status(:success)
      end

      context "when contest is not accepting entries" do
        let(:finished_contest) { create(:contest, :finished, user: organizer) }

        it "returns not found" do
          get new_contest_entry_path(finished_contest)
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "POST /contests/:contest_id/entries" do
    let(:valid_params) do
      {
        entry: {
          title: "テスト写真",
          description: "これはテストです",
          location: "東京",
          taken_at: Date.current,
          photo: fixture_file_upload('spec/fixtures/files/test_image.jpg', 'image/jpeg')
        }
      }
    end

    context "when not signed in" do
      it "redirects to login page" do
        post contest_entries_path(contest), params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before do
        sign_in user
        FileUtils.mkdir_p(Rails.root.join('spec/fixtures/files'))
        File.write(Rails.root.join('spec/fixtures/files/test_image.jpg'), 'fake image data')
      end

      it "creates a new entry" do
        expect {
          post contest_entries_path(contest), params: valid_params
        }.to change(Entry, :count).by(1)
      end

      it "redirects to entry page after creation" do
        post contest_entries_path(contest), params: valid_params
        expect(response).to redirect_to(entry_path(Entry.last))
      end

      context "with invalid params" do
        it "does not create an entry without photo" do
          invalid_params = { entry: { title: "テスト" } }
          expect {
            post contest_entries_path(contest), params: invalid_params
          }.not_to change(Entry, :count)
        end
      end

      context "when contest is not accepting entries" do
        let(:finished_contest) { create(:contest, :finished, user: organizer) }

        it "returns not found" do
          post contest_entries_path(finished_contest), params: valid_params
          expect(response).to have_http_status(:not_found)
        end
      end

      context "with spot integration" do
        let(:spot) { create(:spot, contest: contest) }

        it "creates an entry with spot_id" do
          params_with_spot = valid_params.deep_merge(entry: { spot_id: spot.id })
          expect {
            post contest_entries_path(contest), params: params_with_spot
          }.to change(Entry, :count).by(1)
          expect(Entry.last.spot).to eq(spot)
        end

        context "when spot belongs to different contest" do
          let(:other_contest) { create(:contest, :published, user: organizer) }
          let(:other_spot) { create(:spot, contest: other_contest) }

          it "does not create an entry" do
            params_with_other_spot = valid_params.deep_merge(entry: { spot_id: other_spot.id })
            expect {
              post contest_entries_path(contest), params: params_with_other_spot
            }.not_to change(Entry, :count)
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end

        context "when contest requires spot" do
          let(:contest_with_spot_required) { create(:contest, :published, user: organizer, require_spot: true) }
          let(:required_spot) { create(:spot, contest: contest_with_spot_required) }

          it "does not create an entry without spot_id" do
            expect {
              post contest_entries_path(contest_with_spot_required), params: valid_params
            }.not_to change(Entry, :count)
            expect(response).to have_http_status(:unprocessable_entity)
          end

          it "creates an entry with spot_id" do
            params_with_required_spot = valid_params.deep_merge(entry: { spot_id: required_spot.id })
            expect {
              post contest_entries_path(contest_with_spot_required), params: params_with_required_spot
            }.to change(Entry, :count).by(1)
            expect(Entry.last.spot).to eq(required_spot)
          end
        end
      end
    end
  end

  describe "GET /entries/:id" do
    let!(:entry) { create(:entry, user: user, contest: contest, moderation_status: :moderation_approved) }

    context "when not signed in" do
      it "returns success for public entry" do
        get entry_path(entry)
        expect(response).to have_http_status(:success)
      end

      it "returns not found for hidden entry" do
        entry.update!(moderation_status: :moderation_hidden)
        get entry_path(entry)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when signed in as owner" do
      before { sign_in user }

      it "returns success" do
        get entry_path(entry)
        expect(response).to have_http_status(:success)
      end

      it "can view own hidden entry" do
        entry.update!(moderation_status: :moderation_hidden)
        get entry_path(entry)
        expect(response).to have_http_status(:success)
      end
    end

    context "when signed in as other user" do
      before { sign_in other_user }

      it "can view entry (entries are public)" do
        get entry_path(entry)
        expect(response).to have_http_status(:success)
      end
    end

    context "when similar entries exist" do
      let!(:entry_with_similar) { create(:entry, :with_exif, user: user, contest: contest, moderation_status: :moderation_approved) }
      let!(:similar_entry) { create(:entry, user: user, contest: contest, title: "Similar Work", moderation_status: :moderation_approved) }

      it "displays related works section" do
        get entry_path(entry_with_similar)
        expect(response.body).to include(I18n.t('entries.show.similar_entries'))
      end
    end

    context "when entry has EXIF data" do
      let!(:entry_with_exif) { create(:entry, :with_exif, user: user, contest: contest, moderation_status: :moderation_approved) }

      it "displays camera model" do
        get entry_path(entry_with_exif)
        expect(response.body).to include("Canon Canon EOS R5")
      end

      it "displays shooting parameters" do
        get entry_path(entry_with_exif)
        expect(response.body).to include("f/2.8")
        expect(response.body).to include("1/250s")
        expect(response.body).to include("ISO 400")
        expect(response.body).to include("50mm")
      end
    end

    context "when entry has no EXIF data" do
      let!(:entry_no_exif) { create(:entry, user: user, contest: contest, exif_data: nil, moderation_status: :moderation_approved) }

      it "does not display EXIF section" do
        get entry_path(entry_no_exif)
        expect(response.body).not_to include("exif-section")
      end
    end

    context "when entry has spot" do
      let(:spot) { create(:spot, :with_coordinates, contest: contest, name: "テストスポット") }
      let!(:entry_with_spot) { create(:entry, user: user, contest: contest, spot: spot, moderation_status: :moderation_approved) }

      it "displays spot information" do
        get entry_path(entry_with_spot)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("テストスポット")
      end
    end
  end

  describe "GET /entries/:id/edit" do
    let!(:entry) { create(:entry, user: user, contest: contest) }

    context "when not signed in" do
      it "redirects to login page" do
        get edit_entry_path(entry)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as owner" do
      before { sign_in user }

      it "returns success" do
        get edit_entry_path(entry)
        expect(response).to have_http_status(:success)
      end

      context "when contest is not accepting entries" do
        before do
          contest.update!(status: :finished)
        end

        it "redirects to entry page" do
          get edit_entry_path(entry)
          expect(response).to redirect_to(entry_path(entry))
        end
      end
    end

    context "when signed in as other user" do
      before { sign_in other_user }

      it "redirects to my entries page" do
        get edit_entry_path(entry)
        expect(response).to redirect_to(my_entries_path)
      end
    end
  end

  describe "PATCH /entries/:id" do
    let!(:entry) { create(:entry, user: user, contest: contest) }

    context "when not signed in" do
      it "redirects to login page" do
        patch entry_path(entry), params: { entry: { title: "更新" } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as owner" do
      before { sign_in user }

      it "updates the entry" do
        patch entry_path(entry), params: { entry: { title: "更新されたタイトル" } }
        expect(entry.reload.title).to eq("更新されたタイトル")
      end

      it "redirects to entry page after update" do
        patch entry_path(entry), params: { entry: { title: "更新" } }
        expect(response).to redirect_to(entry_path(entry))
      end

      context "when contest is not accepting entries" do
        before do
          contest.update!(status: :finished)
        end

        it "redirects to entry page without updating" do
          patch entry_path(entry), params: { entry: { title: "更新" } }
          expect(response).to redirect_to(entry_path(entry))
          expect(entry.reload.title).not_to eq("更新")
        end
      end

      context "with spot integration" do
        let(:spot) { create(:spot, contest: contest) }

        it "updates the entry with spot_id" do
          patch entry_path(entry), params: { entry: { spot_id: spot.id } }
          expect(entry.reload.spot).to eq(spot)
        end

        context "when spot belongs to different contest" do
          let(:other_contest) { create(:contest, :published, user: organizer) }
          let(:other_spot) { create(:spot, contest: other_contest) }

          it "does not update the entry" do
            patch entry_path(entry), params: { entry: { spot_id: other_spot.id } }
            expect(response).to have_http_status(:unprocessable_entity)
            expect(entry.reload.spot).to be_nil
          end
        end
      end
    end

    context "when signed in as other user" do
      before { sign_in other_user }

      it "redirects to my entries page" do
        patch entry_path(entry), params: { entry: { title: "更新" } }
        expect(response).to redirect_to(my_entries_path)
      end
    end
  end

  describe "DELETE /entries/:id" do
    let!(:entry) { create(:entry, user: user, contest: contest) }

    context "when not signed in" do
      it "redirects to login page" do
        delete entry_path(entry)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as owner" do
      before { sign_in user }

      it "deletes the entry" do
        expect {
          delete entry_path(entry)
        }.to change(Entry, :count).by(-1)
      end

      it "redirects to my entries page" do
        delete entry_path(entry)
        expect(response).to redirect_to(my_entries_path)
      end

      context "when contest is not accepting entries" do
        before do
          contest.update!(status: :finished)
        end

        it "does not delete the entry" do
          expect {
            delete entry_path(entry)
          }.not_to change(Entry, :count)
          expect(response).to redirect_to(entry_path(entry))
        end
      end
    end

    context "when signed in as other user" do
      before { sign_in other_user }

      it "redirects to my entries page" do
        delete entry_path(entry)
        expect(response).to redirect_to(my_entries_path)
      end
    end
  end
end
