# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#rank_badge_class" do
    it "returns correct class for rank 1" do
      expect(helper.rank_badge_class(1)).to include("bg-yellow-400")
    end

    it "returns correct class for rank 4+" do
      expect(helper.rank_badge_class(5)).to include("bg-gray-100")
    end
  end

  describe "#rank_label" do
    it "returns grand_prize for rank 1" do
      expect(helper.rank_label(1)).to eq(I18n.t('ranks.grand_prize'))
    end

    it "returns award for rank 4+" do
      expect(helper.rank_label(5)).to eq(I18n.t('ranks.award'))
    end
  end
end
