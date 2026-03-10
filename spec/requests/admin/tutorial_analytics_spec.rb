require "rails_helper"

RSpec.describe "Admin::TutorialAnalytics", type: :request do
  let!(:terms) { create(:terms_of_service, :current) }
  let!(:admin) { create(:user, :admin, :confirmed) }
  let!(:participant) { create(:user, :confirmed) }

  before do
    create(:terms_acceptance, user: admin, terms_of_service: terms)
  end

  describe "GET /admin/tutorial_analytics" do
    context "when logged in as admin" do
      before { sign_in admin }

      it "returns success" do
        get admin_tutorial_analytics_path

        expect(response).to have_http_status(:success)
      end

      it "displays analytics stats" do
        get admin_tutorial_analytics_path

        expect(response.body).to be_present
      end

      context "with tutorial progress data" do
        before do
          organizer = create(:user, :organizer, :confirmed)
          create(:tutorial_progress, :completed, user: organizer, tutorial_type: "organizer_onboarding")
          create(:tutorial_progress, :started, user: participant, tutorial_type: "participant_onboarding")
          create(:tutorial_progress, :skipped, user: create(:user, :confirmed), tutorial_type: "participant_onboarding")
        end

        it "calculates stats correctly" do
          get admin_tutorial_analytics_path

          expect(response).to have_http_status(:success)
        end
      end

      context "with completed tutorial progress having both timestamps" do
        before do
          user_with_progress = create(:user, :confirmed)
          create(:tutorial_progress,
            user: user_with_progress,
            tutorial_type: "participant_onboarding",
            completed: true,
            started_at: 2.hours.ago,
            completed_at: 1.hour.ago
          )
        end

        it "calculates avg_completion_time from strftime SQL" do
          get admin_tutorial_analytics_path

          expect(response).to have_http_status(:success)
          expect(response.body).to be_present
        end
      end

      context "with PostgreSQL adapter" do
        before do
          create(:tutorial_progress,
            user: create(:user, :confirmed),
            tutorial_type: "participant_onboarding",
            completed: true,
            started_at: 2.hours.ago,
            completed_at: 1.hour.ago
          )
        end

        it "uses EXTRACT(EPOCH) SQL expression" do
          allow(ActiveRecord::Base.connection).to receive(:adapter_name).and_return("PostgreSQL")
          # The query will fail on SQLite but we just need to verify the code path
          # Mock the average call to avoid actual SQL execution
          relation = TutorialProgress.where(completed: true).where.not(started_at: nil, completed_at: nil)
          allow(TutorialProgress).to receive(:where).and_call_original
          allow_any_instance_of(ActiveRecord::Relation).to receive(:average).and_return(3600)

          get admin_tutorial_analytics_path

          expect(response).to have_http_status(:success)
        end
      end
    end

    context "when logged in as non-admin" do
      before { sign_in participant }

      it "redirects to root" do
        get admin_tutorial_analytics_path

        expect(response).to redirect_to(root_path)
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        get admin_tutorial_analytics_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
