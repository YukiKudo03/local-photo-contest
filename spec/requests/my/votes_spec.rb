require 'rails_helper'

RSpec.describe "My::Votes", type: :request do
  let(:user) { create(:user, :confirmed) }
  let(:other_user) { create(:user, :confirmed) }
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }

  describe "GET /my/votes" do
    context "when not signed in" do
      it "redirects to login page" do
        get my_votes_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "returns success" do
        get my_votes_path
        expect(response).to have_http_status(:success)
      end

      it "displays only current user's votes" do
        entry1 = create(:entry, contest: contest, title: "自分が投票した作品")
        entry2 = create(:entry, contest: contest, title: "他人が投票した作品")

        create(:vote, user: user, entry: entry1)
        create(:vote, user: other_user, entry: entry2)

        get my_votes_path

        expect(response.body).to include("自分が投票した作品")
        expect(response.body).not_to include("他人が投票した作品")
      end

      it "displays votes in recent order" do
        entry1 = create(:entry, contest: contest, title: "古い投票")
        entry2 = create(:entry, contest: contest, title: "新しい投票")

        create(:vote, user: user, entry: entry1)
        create(:vote, user: user, entry: entry2)

        get my_votes_path

        expect(response.body.index("新しい投票")).to be < response.body.index("古い投票")
      end
    end
  end
end
