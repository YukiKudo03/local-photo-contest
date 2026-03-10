# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImageAnalysisHelper, type: :helper do
  describe "#quality_score_label" do
    context "when score is 80-100 (excellent)" do
      it "returns excellent label for score 90" do
        expect(helper.quality_score_label(90)).to eq(I18n.t("image_analysis.quality_score.excellent"))
      end

      it "returns excellent label for boundary score 80" do
        expect(helper.quality_score_label(80)).to eq(I18n.t("image_analysis.quality_score.excellent"))
      end
    end

    context "when score is 60-79 (good)" do
      it "returns good label for score 70" do
        expect(helper.quality_score_label(70)).to eq(I18n.t("image_analysis.quality_score.good"))
      end

      it "returns good label for boundary score 79" do
        expect(helper.quality_score_label(79)).to eq(I18n.t("image_analysis.quality_score.good"))
      end

      it "returns good label for boundary score 60" do
        expect(helper.quality_score_label(60)).to eq(I18n.t("image_analysis.quality_score.good"))
      end
    end

    context "when score is 40-59 (average)" do
      it "returns average label for score 50" do
        expect(helper.quality_score_label(50)).to eq(I18n.t("image_analysis.quality_score.average"))
      end

      it "returns average label for boundary score 59" do
        expect(helper.quality_score_label(59)).to eq(I18n.t("image_analysis.quality_score.average"))
      end

      it "returns average label for boundary score 40" do
        expect(helper.quality_score_label(40)).to eq(I18n.t("image_analysis.quality_score.average"))
      end
    end

    context "when score is below 40 (below_average)" do
      it "returns below_average label for score 30" do
        expect(helper.quality_score_label(30)).to eq(I18n.t("image_analysis.quality_score.below_average"))
      end

      it "returns below_average label for boundary score 39" do
        expect(helper.quality_score_label(39)).to eq(I18n.t("image_analysis.quality_score.below_average"))
      end
    end
  end
end
