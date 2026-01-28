# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers::Moderation", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:other_organizer) { create(:user, :organizer, :confirmed) }
  let(:regular_user) { create(:user, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer, moderation_enabled: true) }
  let(:other_contest) { create(:contest, :published, user: other_organizer) }

  describe "GET /organizers/contests/:contest_id/moderation" do
    context "when not signed in" do
      it "redirects to login page" do
        get organizers_contest_moderation_index_path(contest)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as regular user" do
      before { sign_in regular_user }

      it "returns forbidden" do
        get organizers_contest_moderation_index_path(contest)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when signed in as organizer" do
      before { sign_in organizer }

      it "returns success for own contest" do
        get organizers_contest_moderation_index_path(contest)
        expect(response).to have_http_status(:success)
      end

      it "redirects when accessing other organizer's contest" do
        get organizers_contest_moderation_index_path(other_contest)
        expect(response).to redirect_to(organizers_contests_path)
      end

      it "displays entries requiring review" do
        entry_review = create(:entry, contest: contest, title: "要確認", moderation_status: :moderation_requires_review)
        entry_hidden = create(:entry, contest: contest, title: "非表示", moderation_status: :moderation_hidden)
        entry_approved = create(:entry, contest: contest, title: "承認済み", moderation_status: :moderation_approved)

        get organizers_contest_moderation_index_path(contest)

        expect(response.body).to include("要確認")
        expect(response.body).to include("非表示")
        expect(response.body).not_to include("承認済み")
      end

      it "shows detected labels from moderation result" do
        entry = create(:entry, contest: contest, moderation_status: :moderation_requires_review)
        create(:moderation_result, entry: entry, labels: [ { "Name" => "Explicit Content", "Confidence" => 85.5 } ])

        get organizers_contest_moderation_index_path(contest)

        expect(response.body).to include("Explicit Content")
        expect(response.body).to include("85.5")
      end
    end
  end

  describe "PATCH /organizers/contests/:contest_id/moderation/:id/approve" do
    let!(:entry) { create(:entry, contest: contest, moderation_status: :moderation_requires_review) }
    let!(:moderation_result) { create(:moderation_result, entry: entry) }

    context "when not signed in" do
      it "redirects to login page" do
        patch approve_organizers_contest_moderation_path(contest, entry)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as organizer" do
      before { sign_in organizer }

      it "approves the entry" do
        patch approve_organizers_contest_moderation_path(contest, entry)
        expect(entry.reload).to be_moderation_approved
      end

      it "updates moderation result" do
        patch approve_organizers_contest_moderation_path(contest, entry)
        moderation_result.reload
        expect(moderation_result.status).to eq("approved")
        expect(moderation_result.reviewed_by).to eq(organizer)
        expect(moderation_result.reviewed_at).not_to be_nil
      end

      it "redirects back to moderation index" do
        patch approve_organizers_contest_moderation_path(contest, entry)
        expect(response).to redirect_to(organizers_contest_moderation_index_path(contest))
      end

      it "responds with turbo_stream when requested" do
        patch approve_organizers_contest_moderation_path(contest, entry),
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "returns not found for entry from other contest" do
        other_entry = create(:entry, contest: other_contest, moderation_status: :moderation_requires_review)
        patch approve_organizers_contest_moderation_path(contest, other_entry)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH /organizers/contests/:contest_id/moderation/:id/reject" do
    let!(:entry) { create(:entry, contest: contest, moderation_status: :moderation_requires_review) }
    let!(:moderation_result) { create(:moderation_result, entry: entry) }

    context "when not signed in" do
      it "redirects to login page" do
        patch reject_organizers_contest_moderation_path(contest, entry)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in as organizer" do
      before { sign_in organizer }

      it "rejects the entry (sets to hidden)" do
        patch reject_organizers_contest_moderation_path(contest, entry)
        expect(entry.reload).to be_moderation_hidden
      end

      it "updates moderation result" do
        patch reject_organizers_contest_moderation_path(contest, entry)
        moderation_result.reload
        expect(moderation_result.status).to eq("rejected")
        expect(moderation_result.reviewed_by).to eq(organizer)
        expect(moderation_result.reviewed_at).not_to be_nil
      end

      it "redirects back to moderation index" do
        patch reject_organizers_contest_moderation_path(contest, entry)
        expect(response).to redirect_to(organizers_contest_moderation_index_path(contest))
      end

      it "responds with turbo_stream when requested" do
        patch reject_organizers_contest_moderation_path(contest, entry),
              headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "returns not found for entry from other contest" do
        other_entry = create(:entry, contest: other_contest, moderation_status: :moderation_requires_review)
        patch reject_organizers_contest_moderation_path(contest, other_entry)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
