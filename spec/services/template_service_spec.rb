# frozen_string_literal: true

require "rails_helper"

RSpec.describe TemplateService do
  let(:organizer) { create(:user, :organizer, :confirmed) }
  let(:category) { create(:category) }
  let(:area) { create(:area, user: organizer) }
  let(:contest) do
    create(:contest,
      user: organizer,
      theme: "テストテーマ",
      description: "テスト説明",
      judging_method: :hybrid,
      judge_weight: 60,
      prize_count: 5,
      moderation_enabled: true,
      moderation_threshold: 70.0,
      require_spot: true,
      category: category,
      area: area
    )
  end

  describe ".create_from_contest" do
    it "creates a template from contest with correct attributes" do
      template = described_class.create_from_contest(contest, name: "テストテンプレート", user: organizer)

      expect(template).to be_persisted
      expect(template.name).to eq("テストテンプレート")
      expect(template.user).to eq(organizer)
      expect(template.source_contest).to eq(contest)
      expect(template.theme).to eq("テストテーマ")
      expect(template.description).to eq("テスト説明")
      expect(template.judging_method).to eq("hybrid")
      expect(template.judge_weight).to eq(60)
      expect(template.prize_count).to eq(5)
      expect(template.moderation_enabled).to be true
      expect(template.moderation_threshold).to eq(70.0)
      expect(template.require_spot).to be true
      expect(template.category).to eq(category)
      expect(template.area).to eq(area)
    end

    it "returns template with errors when name is blank" do
      template = described_class.create_from_contest(contest, name: "", user: organizer)

      expect(template).not_to be_persisted
      expect(template.errors[:name]).to be_present
    end

    it "returns template with errors when name is duplicate" do
      create(:contest_template, user: organizer, name: "既存テンプレート")
      template = described_class.create_from_contest(contest, name: "既存テンプレート", user: organizer)

      expect(template).not_to be_persisted
      expect(template.errors[:name]).to be_present
    end
  end

  describe ".apply_to_contest" do
    let(:template) do
      create(:contest_template,
        user: organizer,
        theme: "テンプレートテーマ",
        description: "テンプレート説明",
        judging_method: :vote_only,
        judge_weight: nil,
        prize_count: 3,
        moderation_enabled: false,
        moderation_threshold: 50.0,
        require_spot: true,
        category: category,
        area: area
      )
    end

    it "applies template settings to contest" do
      new_contest = Contest.new
      result = described_class.apply_to_contest(template, new_contest)

      expect(result).to eq(new_contest)
      expect(result.theme).to eq("テンプレートテーマ")
      expect(result.description).to eq("テンプレート説明")
      expect(result.judging_method).to eq("vote_only")
      expect(result.prize_count).to eq(3)
      expect(result.moderation_enabled).to be false
      expect(result.moderation_threshold).to eq(50.0)
      expect(result.require_spot).to be true
      expect(result.category).to eq(category)
      expect(result.area).to eq(area)
    end

    it "does not save the contest" do
      new_contest = Contest.new
      described_class.apply_to_contest(template, new_contest)

      expect(new_contest).not_to be_persisted
    end

    it "does not apply nil values except for boolean false" do
      template_with_nils = create(:contest_template,
        user: organizer,
        theme: nil,
        description: nil,
        moderation_enabled: false
      )

      new_contest = Contest.new(theme: "既存テーマ", description: "既存説明")
      described_class.apply_to_contest(template_with_nils, new_contest)

      expect(new_contest.theme).to eq("既存テーマ")
      expect(new_contest.description).to eq("既存説明")
      expect(new_contest.moderation_enabled).to be false
    end
  end

  describe ".template_attributes" do
    it "extracts only template-worthy attributes" do
      attrs = described_class.template_attributes(contest)

      expect(attrs.keys).to contain_exactly(
        :theme, :description, :judging_method, :judge_weight, :prize_count,
        :moderation_enabled, :moderation_threshold, :require_spot, :area_id, :category_id
      )
      expect(attrs[:theme]).to eq("テストテーマ")
      expect(attrs[:description]).to eq("テスト説明")
      expect(attrs[:judging_method]).to eq("hybrid")
      expect(attrs[:category_id]).to eq(category.id)
      expect(attrs[:area_id]).to eq(area.id)
    end

    it "does not include title or dates" do
      attrs = described_class.template_attributes(contest)

      expect(attrs).not_to have_key(:title)
      expect(attrs).not_to have_key(:entry_start_at)
      expect(attrs).not_to have_key(:entry_end_at)
      expect(attrs).not_to have_key(:status)
    end
  end

  describe "TEMPLATE_FIELDS" do
    it "contains expected fields" do
      expected_fields = %i[
        theme description judging_method judge_weight prize_count
        moderation_enabled moderation_threshold require_spot area_id category_id
      ]

      expect(described_class::TEMPLATE_FIELDS).to contain_exactly(*expected_fields)
    end
  end
end
