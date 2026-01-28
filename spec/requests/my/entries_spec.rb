require 'rails_helper'

RSpec.describe "My::Entries", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:other_user) { create(:user, :confirmed) }
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }

  describe "GET /my/entries" do
    context "when not signed in" do
      it "redirects to login page" do
        get my_entries_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "returns success" do
        get my_entries_path
        expect(response).to have_http_status(:success)
      end

      it "displays only current user's entries" do
        user_entry = create(:entry, user: user, contest: contest, title: "自分の応募")
        other_entry = create(:entry, user: other_user, contest: contest, title: "他人の応募")

        get my_entries_path

        expect(response.body).to include("自分の応募")
        expect(response.body).not_to include("他人の応募")
      end

      it "displays entries in recent order" do
        old_entry = create(:entry, user: user, contest: contest, title: "古い応募")
        new_entry = create(:entry, user: user, contest: contest, title: "新しい応募")

        get my_entries_path

        expect(response.body.index("新しい応募")).to be < response.body.index("古い応募")
      end
    end
  end
end
