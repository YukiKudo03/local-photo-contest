# frozen_string_literal: true

module ImageAnalysisHelper
  def quality_score_label(score)
    case score
    when 80..100
      t("image_analysis.quality_score.excellent")
    when 60..80
      t("image_analysis.quality_score.good")
    when 40..60
      t("image_analysis.quality_score.average")
    else
      t("image_analysis.quality_score.below_average")
    end
  end
end
