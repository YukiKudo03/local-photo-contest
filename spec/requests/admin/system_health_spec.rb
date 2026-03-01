# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::SystemHealth", type: :request do
  let!(:terms) { create(:terms_of_service, :current) }
  let!(:admin) { create(:user, :admin, :confirmed) }

  before do
    create(:terms_acceptance, user: admin, terms_of_service: terms)
    sign_in admin
  end

  describe "GET /admin/system_health" do
    it "returns success" do
      get admin_system_health_path
      expect(response).to have_http_status(:success)
    end

    it "displays database status" do
      get admin_system_health_path
      expect(response.body).to include("database-status")
    end

    it "displays application info" do
      get admin_system_health_path
      expect(response.body).to include(Rails.version)
    end

    it "displays storage info" do
      get admin_system_health_path
      expect(response.body).to include("storage-status")
    end
  end

  context "when not admin" do
    let!(:participant) { create(:user, :confirmed) }

    before do
      create(:terms_acceptance, user: participant, terms_of_service: terms)
      sign_in participant
    end

    it "redirects to root" do
      get admin_system_health_path
      expect(response).to redirect_to(root_path)
    end
  end
end
