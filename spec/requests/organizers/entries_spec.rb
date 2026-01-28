require 'rails_helper'

RSpec.describe "Organizers::Entries", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:other_organizer) { create(:user, :organizer, :confirmed) }
  let(:regular_user) { create(:user, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }
  let(:other_contest) { create(:contest, :published, user: other_organizer) }

  describe "GET /organizers/contests/:contest_id/entries" do
    context "when not signed in" do
      it "redirects to login page" do
        get organizers_contest_entries_path(contest)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as regular user" do
      before { sign_in regular_user }

      it "returns forbidden" do
        get organizers_contest_entries_path(contest)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when signed in as organizer" do
      before { sign_in organizer }

      it "returns success for own contest" do
        get organizers_contest_entries_path(contest)
        expect(response).to have_http_status(:success)
      end

      it "redirects when accessing other organizer's contest" do
        get organizers_contest_entries_path(other_contest)
        expect(response).to redirect_to(organizers_contests_path)
      end

      it "displays all entries for the contest" do
        entry1 = create(:entry, contest: contest, title: "応募1")
        entry2 = create(:entry, contest: contest, title: "応募2")

        get organizers_contest_entries_path(contest)

        expect(response.body).to include("応募1")
        expect(response.body).to include("応募2")
      end

      it "displays entry count" do
        create_list(:entry, 3, contest: contest)

        get organizers_contest_entries_path(contest)

        expect(response.body).to include("3")
      end
    end
  end

  describe "GET /organizers/contests/:contest_id/entries/:id" do
    let!(:entry) { create(:entry, contest: contest) }
    let!(:other_entry) { create(:entry, contest: other_contest) }

    context "when not signed in" do
      it "redirects to login page" do
        get organizers_contest_entry_path(contest, entry)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as regular user" do
      before { sign_in regular_user }

      it "returns forbidden" do
        get organizers_contest_entry_path(contest, entry)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when signed in as organizer" do
      before { sign_in organizer }

      it "returns success for entry in own contest" do
        get organizers_contest_entry_path(contest, entry)
        expect(response).to have_http_status(:success)
      end

      it "redirects when accessing entry in other organizer's contest" do
        get organizers_contest_entry_path(other_contest, other_entry)
        expect(response).to redirect_to(organizers_contests_path)
      end

      it "returns not found for entry from different contest" do
        get organizers_contest_entry_path(contest, other_entry)
        expect(response).to have_http_status(:not_found)
      end

      it "displays entry details" do
        get organizers_contest_entry_path(contest, entry)

        expect(response.body).to include(entry.title)
        expect(response.body).to include(entry.user.email)
      end
    end
  end
end
