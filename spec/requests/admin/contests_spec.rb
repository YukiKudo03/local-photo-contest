# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Contests", type: :request do
  let!(:terms) { create(:terms_of_service, :current) }
  let!(:admin) { create(:user, :admin, :confirmed) }
  let!(:organizer) { create(:user, :organizer, :confirmed) }
  let!(:contest) { create(:contest, :accepting_entries, user: organizer) }

  before do
    create(:terms_acceptance, user: admin, terms_of_service: terms)
    create(:terms_acceptance, user: organizer, terms_of_service: terms)
    sign_in admin
  end

  describe "GET /admin/contests" do
    it "returns success" do
      get admin_contests_path
      expect(response).to have_http_status(:success)
    end

    it "displays contest list" do
      get admin_contests_path
      expect(response.body).to include("コンテスト管理")
      expect(response.body).to include(contest.title)
    end

    context "with search query" do
      it "filters contests by title" do
        get admin_contests_path, params: { q: contest.title }
        expect(response.body).to include(contest.title)
      end
    end
  end

  describe "GET /admin/contests/:id" do
    it "returns success" do
      get admin_contest_path(contest)
      expect(response).to have_http_status(:success)
    end

    it "displays contest details" do
      get admin_contest_path(contest)
      expect(response.body).to include(contest.title)
      expect(response.body).to include("総応募数")
    end
  end

  describe "PATCH /admin/contests/:id/force_finish" do
    it "force finishes the contest" do
      patch force_finish_admin_contest_path(contest)
      expect(response).to redirect_to(admin_contest_path(contest))
      expect(contest.reload.finished?).to be true
    end
  end

  describe "DELETE /admin/contests/:id" do
    it "deletes the contest" do
      delete admin_contest_path(contest)
      expect(response).to redirect_to(admin_contests_path)
      expect(Contest.exists?(contest.id)).to be false
    end
  end
end
