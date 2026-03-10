# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Categories", type: :request do
  let!(:terms) { create(:terms_of_service, :current) }
  let!(:admin) { create(:user, :admin, :confirmed) }
  let!(:category) { create(:category, name: "風景", position: 1) }

  before do
    create(:terms_acceptance, user: admin, terms_of_service: terms)
    sign_in admin
  end

  describe "GET /admin/categories" do
    it "returns success" do
      get admin_categories_path
      expect(response).to have_http_status(:success)
    end

    it "displays category list" do
      get admin_categories_path
      expect(response.body).to include("カテゴリ管理")
      expect(response.body).to include(category.name)
    end
  end

  describe "GET /admin/categories/:id" do
    it "returns success" do
      get admin_category_path(category)
      expect(response).to have_http_status(:success)
    end

    it "displays contests associated with the category" do
      organizer = create(:user, :organizer, :confirmed)
      create(:terms_acceptance, user: organizer, terms_of_service: terms)
      create(:contest, user: organizer, category: category)

      get admin_category_path(category)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/categories/new" do
    it "returns success" do
      get new_admin_category_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /admin/categories" do
    it "creates a new category" do
      expect {
        post admin_categories_path, params: { category: { name: "ポートレート", description: "人物写真" } }
      }.to change(Category, :count).by(1)
      expect(response).to redirect_to(admin_categories_path)
    end

    it "rejects invalid category" do
      post admin_categories_path, params: { category: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /admin/categories/:id/edit" do
    it "returns success" do
      get edit_admin_category_path(category)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/categories/:id" do
    it "updates the category" do
      patch admin_category_path(category), params: { category: { name: "山岳" } }
      expect(response).to redirect_to(admin_categories_path)
      expect(category.reload.name).to eq("山岳")
    end

    it "renders edit on invalid update" do
      patch admin_category_path(category), params: { category: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /admin/categories/:id" do
    context "when category has no contests" do
      it "deletes the category" do
        delete admin_category_path(category)
        expect(response).to redirect_to(admin_categories_path)
        expect(Category.exists?(category.id)).to be false
      end
    end

    context "when category has contests" do
      let!(:organizer) { create(:user, :organizer, :confirmed) }
      let!(:contest) { create(:contest, user: organizer, category: category) }

      before do
        create(:terms_acceptance, user: organizer, terms_of_service: terms)
      end

      it "does not delete the category" do
        delete admin_category_path(category)
        expect(response).to redirect_to(admin_categories_path)
        expect(Category.exists?(category.id)).to be true
        follow_redirect!
        expect(response.body).to include("コンテストに関連付けられているため削除できません")
      end
    end
  end
end
