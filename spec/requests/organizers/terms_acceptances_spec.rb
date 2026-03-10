# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Organizers::TermsAcceptances", type: :request do
  let(:organizer) { create(:user, :organizer, :confirmed) }

  describe "GET /organizers/terms/new" do
    context "when not authenticated" do
      it "redirects to login" do
        get new_organizers_terms_acceptance_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as organizer" do
      before { sign_in organizer }

      context "when no current terms exist" do
        it "redirects to dashboard" do
          get new_organizers_terms_acceptance_path
          expect(response).to redirect_to(organizers_dashboard_path)
        end
      end

      context "when terms exist and not yet accepted" do
        let!(:terms) { create(:terms_of_service, :current) }

        it "returns success" do
          get new_organizers_terms_acceptance_path
          expect(response).to have_http_status(:success)
        end
      end

      context "when terms exist and already accepted" do
        let!(:terms) { create(:terms_of_service, :current) }

        before do
          create(:terms_acceptance, user: organizer, terms_of_service: terms)
        end

        it "redirects to dashboard" do
          get new_organizers_terms_acceptance_path
          expect(response).to redirect_to(organizers_dashboard_path)
        end
      end
    end
  end

  describe "POST /organizers/terms" do
    context "when not authenticated" do
      it "redirects to login" do
        post organizers_terms_acceptances_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as organizer" do
      before { sign_in organizer }

      context "when current terms exist" do
        let!(:terms) { create(:terms_of_service, :current) }

        it "creates terms acceptance and redirects" do
          expect {
            post organizers_terms_acceptances_path
          }.to change(TermsAcceptance, :count).by(1)

          expect(response).to redirect_to(organizers_dashboard_path)
        end

        it "sets flash notice" do
          post organizers_terms_acceptances_path
          expect(flash[:notice]).to be_present
        end
      end

      context "when no current terms exist" do
        it "redirects to dashboard without creating acceptance" do
          expect {
            post organizers_terms_acceptances_path
          }.not_to change(TermsAcceptance, :count)

          expect(response).to redirect_to(organizers_dashboard_path)
        end
      end
    end
  end
end
