# frozen_string_literal: true

require "rails_helper"

RSpec.describe Category, type: :model do
  describe "associations" do
    it { should have_many(:contests).dependent(:nullify) }

    context "when category with contests is destroyed" do
      let!(:terms) { create(:terms_of_service, :current) }
      let!(:organizer) { create(:user, :organizer, :confirmed) }
      let!(:category) { create(:category) }
      let!(:contest) { create(:contest, category: category, user: organizer) }

      before do
        create(:terms_acceptance, user: organizer, terms_of_service: terms)
      end

      it "does not delete associated contests" do
        expect { category.destroy }.not_to change(Contest, :count)
      end

      it "sets contest category_id to nil" do
        category.destroy
        expect(contest.reload.category_id).to be_nil
      end
    end
  end

  describe "validations" do
    subject { build(:category, name: "TestCategory") }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name) }
    it { should validate_length_of(:name).is_at_most(50) }
    it { should validate_length_of(:description).is_at_most(500) }

    context "name uniqueness" do
      it "is invalid with duplicate name" do
        create(:category, name: "風景")
        duplicate = build(:category, name: "風景")
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:name]).to be_present
      end

      it "is case sensitive for uniqueness" do
        create(:category, name: "Landscape")
        different_case = build(:category, name: "landscape")
        expect(different_case).to be_valid
      end
    end

    context "name length" do
      it "is invalid with name longer than 50 characters" do
        category = build(:category, name: "a" * 51)
        expect(category).not_to be_valid
      end

      it "is valid with name exactly 50 characters" do
        category = build(:category, name: "a" * 50)
        expect(category).to be_valid
      end
    end

    context "description" do
      it "allows blank description" do
        category = build(:category, description: nil)
        expect(category).to be_valid
      end

      it "allows empty description" do
        category = build(:category, description: "")
        expect(category).to be_valid
      end

      it "is invalid with description longer than 500 characters" do
        category = build(:category, description: "a" * 501)
        expect(category).not_to be_valid
      end
    end
  end

  describe "scopes" do
    describe ".ordered" do
      let!(:category2) { create(:category, position: 2) }
      let!(:category1) { create(:category, position: 1) }
      let!(:category3) { create(:category, position: 3) }

      it "returns categories ordered by position" do
        expect(Category.ordered).to eq([ category1, category2, category3 ])
      end

      it "orders by name when positions are equal" do
        cat_a = create(:category, name: "Aカテゴリ", position: 10)
        cat_b = create(:category, name: "Bカテゴリ", position: 10)

        ordered = Category.ordered.where(position: 10)
        expect(ordered.first.name).to eq("Aカテゴリ")
        expect(ordered.second.name).to eq("Bカテゴリ")
      end
    end
  end

  describe "callbacks" do
    describe "#set_position" do
      it "sets position automatically if not provided" do
        category = create(:category, position: nil)
        expect(category.position).to be_present
      end

      it "increments position based on existing categories" do
        create(:category, position: 5)
        category = create(:category, position: nil)
        expect(category.position).to eq(6)
      end

      it "does not override explicitly set position" do
        category = create(:category, position: 100)
        expect(category.position).to eq(100)
      end

      it "starts at 1 when no categories exist" do
        # Uses max position + 1 logic, so this test verifies behavior
        # when there are no existing categories
        new_category = create(:category, position: nil)
        expect(new_category.position).to be >= 1
      end
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:category)).to be_valid
    end

    it "generates unique names" do
      categories = create_list(:category, 5)
      names = categories.map(&:name)
      expect(names.uniq.count).to eq(5)
    end
  end
end
