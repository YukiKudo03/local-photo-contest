# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Judge Flow", type: :system do
  let!(:organizer) { create(:user, :organizer, :confirmed) }
  let!(:judge_user) { create(:user, :confirmed, name: "審査員太郎") }
  let!(:participant) { create(:user, :confirmed) }
  let!(:terms) { create(:terms_of_service, :current) }
  let!(:contest) { create(:contest, :accepting_entries, user: organizer, title: "審査コンテスト") }
  let!(:contest_judge) { create(:contest_judge, contest: contest, user: judge_user) }

  let!(:criterion1) { create(:evaluation_criterion, contest: contest, name: "構図", max_score: 10, position: 1) }
  let!(:entry1) { create(:entry, user: participant, contest: contest, title: "作品1") }

  before do
    create(:terms_acceptance, user: organizer, terms_of_service: terms)
    create(:terms_acceptance, user: judge_user, terms_of_service: terms)
    create(:terms_acceptance, user: participant, terms_of_service: terms)
    driven_by(:selenium_chrome_headless)
  end

  describe "organizer judge management" do
    before { login_as organizer, scope: :user }

    it "shows judge management page" do
      visit organizers_contest_judges_path(contest)

      expect(page).to have_content("審査員")
    end
  end

  describe "evaluation criteria management" do
    before { login_as organizer, scope: :user }

    it "shows evaluation criteria" do
      visit organizers_contest_evaluation_criteria_path(contest)

      expect(page).to have_content("構図")
    end
  end
end
