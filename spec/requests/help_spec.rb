# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Help", type: :request do
  describe "GET /help" do
    it "returns successful response" do
      get help_path
      expect(response).to have_http_status(:success)
    end

    it "displays the page title" do
      get help_path
      expect(response.body).to include("利用ガイド")
    end

    it "displays all four guide cards" do
      get help_path
      expect(response.body).to include("参加者向けマニュアル")
      expect(response.body).to include("主催者向けマニュアル")
      expect(response.body).to include("審査員向けマニュアル")
      expect(response.body).to include("管理者向けマニュアル")
    end

    it "includes links to each guide" do
      get help_path
      expect(response.body).to include(help_guide_path(:participant))
      expect(response.body).to include(help_guide_path(:organizer))
      expect(response.body).to include(help_guide_path(:judge))
      expect(response.body).to include(help_guide_path(:admin))
    end

    context "when not logged in" do
      it "allows access to the help page" do
        get help_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when logged in" do
      let(:user) { create(:user, :confirmed) }

      before { sign_in user }

      it "allows access to the help page" do
        get help_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /help/:guide" do
    context "with participant guide" do
      it "returns successful response" do
        get help_guide_path(:participant)
        expect(response).to have_http_status(:success)
      end

      it "displays the guide title" do
        get help_guide_path(:participant)
        expect(response.body).to include("参加者向けマニュアル")
      end

      it "renders the markdown content" do
        get help_guide_path(:participant)
        # The participant guide should have specific content
        expect(response.body).to include("コンテスト")
      end

      it "includes table of contents" do
        get help_guide_path(:participant)
        expect(response.body).to include("目次")
      end

      it "includes back link" do
        get help_guide_path(:participant)
        expect(response.body).to include("マニュアル一覧に戻る")
      end
    end

    context "with organizer guide" do
      it "returns successful response" do
        get help_guide_path(:organizer)
        expect(response).to have_http_status(:success)
      end

      it "displays the guide title" do
        get help_guide_path(:organizer)
        expect(response.body).to include("主催者向けマニュアル")
      end
    end

    context "with judge guide" do
      it "returns successful response" do
        get help_guide_path(:judge)
        expect(response).to have_http_status(:success)
      end

      it "displays the guide title" do
        get help_guide_path(:judge)
        expect(response.body).to include("審査員向けマニュアル")
      end
    end

    context "with admin guide" do
      it "returns successful response" do
        get help_guide_path(:admin)
        expect(response).to have_http_status(:success)
      end

      it "displays the guide title" do
        get help_guide_path(:admin)
        expect(response.body).to include("管理者向けマニュアル")
      end
    end

    context "with invalid guide" do
      it "returns 404 for non-existent guide" do
        # The route constraint should prevent invalid guides from being matched
        # In Rails test environment, this results in a 404 response
        get "/help/invalid_guide"
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not logged in" do
      it "allows access to guides" do
        get help_guide_path(:participant)
        expect(response).to have_http_status(:success)
      end
    end

    context "when logged in" do
      let(:user) { create(:user, :confirmed) }

      before { sign_in user }

      it "allows access to guides" do
        get help_guide_path(:participant)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "navigation links" do
    let(:user) { create(:user, :confirmed) }

    before { sign_in user }

    it "header includes help link" do
      get root_path
      expect(response.body).to include("ヘルプ")
    end

    it "footer includes help link" do
      get root_path
      expect(response.body).to include("利用ガイド")
    end
  end
end
