# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers::ContestTemplates", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:other_organizer) { create(:user, :organizer, :confirmed) }
  let(:regular_user) { create(:user, :confirmed) }
  let(:contest) { create(:contest, :draft, user: organizer) }
  let(:template) { create(:contest_template, user: organizer) }

  describe "GET /organizers/contest_templates" do
    context "when not authenticated" do
      it "redirects to login page" do
        get organizers_contest_templates_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as organizer" do
      before { sign_in organizer }

      it "returns success" do
        get organizers_contest_templates_path
        expect(response).to have_http_status(:success)
      end

      it "displays user's templates" do
        template = create(:contest_template, user: organizer, name: "マイテンプレート")
        get organizers_contest_templates_path
        expect(response.body).to include("マイテンプレート")
      end

      it "does not display other user's templates" do
        other_template = create(:contest_template, user: other_organizer, name: "他者のテンプレート")
        get organizers_contest_templates_path
        expect(response.body).not_to include("他者のテンプレート")
      end

      it "displays empty state when no templates" do
        get organizers_contest_templates_path
        expect(response.body).to include("テンプレートがありません")
      end
    end

    context "when authenticated as regular user" do
      before { sign_in regular_user }

      it "returns forbidden status" do
        get organizers_contest_templates_path
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /organizers/contest_templates/new" do
    context "when not authenticated" do
      it "redirects to login page" do
        get new_organizers_contest_template_path(contest_id: contest.id)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as organizer" do
      before { sign_in organizer }

      it "returns success" do
        get new_organizers_contest_template_path(contest_id: contest.id)
        expect(response).to have_http_status(:success)
      end

      it "displays contest information" do
        get new_organizers_contest_template_path(contest_id: contest.id)
        expect(response.body).to include(contest.title)
      end

      it "redirects when contest not found" do
        get new_organizers_contest_template_path(contest_id: 0)
        expect(response).to redirect_to(organizers_contests_path)
      end

      it "redirects when accessing other user's contest" do
        other_contest = create(:contest, user: other_organizer)
        get new_organizers_contest_template_path(contest_id: other_contest.id)
        expect(response).to redirect_to(organizers_contests_path)
      end
    end
  end

  describe "POST /organizers/contest_templates" do
    context "when not authenticated" do
      it "redirects to login page" do
        post organizers_contest_templates_path, params: {
          contest_id: contest.id,
          contest_template: { name: "新テンプレート" }
        }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as organizer" do
      before { sign_in organizer }

      it "creates a new template" do
        expect {
          post organizers_contest_templates_path, params: {
            contest_id: contest.id,
            contest_template: { name: "新テンプレート" }
          }
        }.to change(ContestTemplate, :count).by(1)

        expect(response).to redirect_to(organizers_contest_templates_path)
      end

      it "copies contest settings to template" do
        contest.update!(theme: "テストテーマ", prize_count: 5)

        post organizers_contest_templates_path, params: {
          contest_id: contest.id,
          contest_template: { name: "新テンプレート" }
        }

        template = ContestTemplate.last
        expect(template.theme).to eq("テストテーマ")
        expect(template.prize_count).to eq(5)
        expect(template.source_contest).to eq(contest)
      end

      it "renders new with errors when name is blank" do
        post organizers_contest_templates_path, params: {
          contest_id: contest.id,
          contest_template: { name: "" }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders new with errors when name is duplicate" do
        create(:contest_template, user: organizer, name: "既存テンプレート")

        post organizers_contest_templates_path, params: {
          contest_id: contest.id,
          contest_template: { name: "既存テンプレート" }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /organizers/contest_templates/:id" do
    context "when not authenticated" do
      it "redirects to login page" do
        delete organizers_contest_template_path(template)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as template owner" do
      before { sign_in organizer }

      it "deletes the template" do
        template # create template
        expect {
          delete organizers_contest_template_path(template)
        }.to change(ContestTemplate, :count).by(-1)

        expect(response).to redirect_to(organizers_contest_templates_path)
      end
    end

    context "when authenticated as different organizer" do
      before { sign_in other_organizer }

      it "redirects with unauthorized message" do
        delete organizers_contest_template_path(template)
        expect(response).to redirect_to(organizers_contest_templates_path)
        expect(flash[:alert]).to eq("このテンプレートにアクセスする権限がありません。")
      end

      it "does not delete the template" do
        template # create template
        expect {
          delete organizers_contest_template_path(template)
        }.not_to change(ContestTemplate, :count)
      end
    end
  end
end
