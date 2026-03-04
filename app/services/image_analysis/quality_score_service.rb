# frozen_string_literal: true

begin
  require "mini_magick"
rescue LoadError
  # MiniMagick will be loaded when the gem is installed
end

module ImageAnalysis
  class QualityScoreService
    def initialize(entry)
      @entry = entry
    end

    def calculate
      return unless @entry.photo.attached?

      score = 0.0
      score += exif_score
      score += image_score

      normalized = [ [ score, 0.0 ].max, 100.0 ].min.round(1)
      @entry.update_columns(quality_score: normalized, image_analysis_completed_at: Time.current)
      normalized
    rescue StandardError => e
      Rails.logger.error("QualityScoreService: Error for entry #{@entry.id}: #{e.message}")
      nil
    end

    private

    # EXIF-based scoring (50 points max)
    def exif_score
      return 25.0 unless @entry.has_exif_data?

      score = 0.0
      score += iso_score
      score += exposure_score
      score += resolution_score
      score += lens_score
      score
    end

    # ISO score: 0-15 points (lower ISO = higher score)
    def iso_score
      iso = @entry.exif_data["ISOSpeedRatings"].to_i
      return 8.0 if iso == 0

      case iso
      when 0..100 then 15.0
      when 101..200 then 13.0
      when 201..400 then 10.0
      when 401..800 then 7.0
      when 801..1600 then 4.0
      else 1.0
      end
    end

    # Exposure score: 0-10 points
    def exposure_score
      exposure_str = @entry.exif_data["ExposureTime"]
      return 5.0 unless exposure_str.present?

      exposure = Rational(exposure_str).to_f
      return 5.0 if exposure <= 0

      case exposure
      when 0.0001..0.004 then 7.0   # Very fast (1/250 - 1/8000)
      when 0.004..0.017 then 10.0   # Good range (1/60 - 1/250)
      when 0.017..0.125 then 8.0    # Moderate (1/8 - 1/60)
      when 0.125..1.0 then 5.0     # Slow (1s - 1/8)
      else 3.0                      # Very slow or very fast
      end
    rescue ArgumentError, ZeroDivisionError
      5.0
    end

    # Resolution score: 0-15 points
    def resolution_score
      width = @entry.exif_data["ImageWidth"].to_i
      height = @entry.exif_data["ImageHeight"].to_i

      if width == 0 || height == 0
        # Try blob metadata
        blob = @entry.photo.blob
        width = blob.metadata["width"].to_i if blob.metadata
        height = blob.metadata["height"].to_i if blob.metadata
      end

      return 8.0 if width == 0 || height == 0

      megapixels = (width * height) / 1_000_000.0

      case megapixels
      when 20.. then 15.0
      when 12..20 then 12.0
      when 8..12 then 9.0
      when 4..8 then 5.0
      else 2.0
      end
    end

    # Lens quality score: 0-10 points
    def lens_score
      f_number_str = @entry.exif_data["FNumber"]
      focal_str = @entry.exif_data["FocalLength"]
      return 5.0 unless f_number_str.present?

      f_number = Rational(f_number_str).to_f
      focal_length = focal_str.present? ? Rational(focal_str).to_f : 0

      score = 5.0
      # Fast lenses score higher
      score += 3.0 if f_number <= 2.8
      score += 2.0 if f_number > 2.8 && f_number <= 4.0
      # Reasonable focal length range bonus
      score += 2.0 if focal_length >= 24 && focal_length <= 200

      [ score, 10.0 ].min
    rescue ArgumentError, ZeroDivisionError
      5.0
    end

    # MiniMagick-based scoring (50 points max)
    def image_score
      return 25.0 unless defined?(MiniMagick)

      @entry.photo.open do |tempfile|
        image = MiniMagick::Image.new(tempfile.path)
        score = 0.0
        score += sharpness_score(image)
        score += dynamic_range_score(image)
        score += brightness_score(image)
        score
      end
    rescue StandardError => e
      Rails.logger.warn("QualityScoreService: MiniMagick analysis failed: #{e.message}")
      25.0
    end

    # Sharpness score: 0-20 points (Laplacian standard deviation)
    def sharpness_score(image)
      result = MiniMagick.convert do |convert|
        convert << image.path
        convert.colorspace("Gray")
        convert.resize("500x500>")
        convert.laplacian(0)
        convert.format("%[fx:standard_deviation]")
        convert << "info:"
      end

      std_dev = result.strip.to_f
      score = (std_dev * 200).clamp(0, 20)
      score.round(1)
    rescue StandardError
      10.0
    end

    # Dynamic range score: 0-15 points
    def dynamic_range_score(image)
      result = MiniMagick.identify do |identify|
        identify.format("%[fx:maxima - minima]")
        identify << image.path
      end

      range = result.strip.to_f
      score = (range * 15).clamp(0, 15)
      score.round(1)
    rescue StandardError
      7.5
    end

    # Brightness score: 0-15 points (penalize too dark or too bright)
    def brightness_score(image)
      result = MiniMagick.identify do |identify|
        identify.format("%[fx:mean]")
        identify << image.path
      end

      mean = result.strip.to_f
      if mean >= 0.3 && mean <= 0.7
        15.0
      elsif mean >= 0.2 && mean <= 0.8
        10.0
      elsif mean >= 0.1 && mean <= 0.9
        5.0
      else
        2.0
      end
    rescue StandardError
      7.5
    end
  end
end
