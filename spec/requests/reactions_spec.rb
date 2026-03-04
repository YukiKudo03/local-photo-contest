# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reactions", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:contest) { create(:contest, :published, user: organizer) }
  let(:entry) { create(:entry, contest: contest) }
  let(:user) { create(:user, :confirmed) }

  describe "POST /entries/:entry_id/reaction" do
    context "when not signed in" do
      it "redirects to login page" do
        post entry_reaction_path(entry)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "creates a like reaction" do
        expect {
          post entry_reaction_path(entry)
        }.to change(Reaction, :count).by(1)
      end

      it "redirects to entry page" do
        post entry_reaction_path(entry)
        expect(response).to redirect_to(entry_path(entry))
      end

      it "toggles off when already liked" do
        create(:reaction, user: user, entry: entry)
        expect {
          post entry_reaction_path(entry)
        }.to change(Reaction, :count).by(-1)
      end

      context "with turbo_stream format" do
        it "responds with turbo_stream" do
          post entry_reaction_path(entry), as: :turbo_stream
          expect(response.media_type).to eq Mime[:turbo_stream]
        end
      end
    end
  end

  describe "DELETE /entries/:entry_id/reaction" do
    context "when signed in" do
      before do
        sign_in user
        create(:reaction, user: user, entry: entry)
      end

      it "toggles the like" do
        expect {
          delete entry_reaction_path(entry)
        }.to change(Reaction, :count).by(-1)
      end
    end
  end
end
