# frozen_string_literal: true

module ExifAccessible
  extend ActiveSupport::Concern

  class_methods do
    def distinct_camera_makes
      where.not(exif_data: nil)
           .where("json_extract(exif_data, '$.Make') IS NOT NULL")
           .pluck(Arel.sql("DISTINCT json_extract(exif_data, '$.Make')"))
           .compact
           .sort
    end

    def distinct_camera_models
      where.not(exif_data: nil)
           .where("json_extract(exif_data, '$.Model') IS NOT NULL")
           .pluck(Arel.sql("DISTINCT json_extract(exif_data, '$.Model')"))
           .compact
           .sort
    end
  end

  def has_exif_data?
    exif_data.present? && exif_data.is_a?(Hash) && exif_data.any?
  end

  def exif_camera_model
    return nil unless has_exif_data?

    make = exif_data["Make"]
    model = exif_data["Model"]
    return nil unless model.present? || make.present?

    [make, model].compact_blank.join(" ").presence
  end

  def exif_focal_length
    return nil unless has_exif_data?

    value = exif_data["FocalLength"]
    return nil unless value.present?

    mm = Rational(value).to_f.round
    "#{mm}mm"
  rescue ArgumentError, ZeroDivisionError
    nil
  end

  def exif_aperture
    return nil unless has_exif_data?

    value = exif_data["FNumber"]
    return nil unless value.present?

    f = Rational(value).to_f
    "f/#{format_number(f)}"
  rescue ArgumentError, ZeroDivisionError
    nil
  end

  def exif_shutter_speed
    return nil unless has_exif_data?

    value = exif_data["ExposureTime"]
    return nil unless value.present?

    "#{value}s"
  end

  def exif_iso
    return nil unless has_exif_data?

    value = exif_data["ISOSpeedRatings"]
    return nil unless value.present?

    "ISO #{value}"
  end

  private

  def format_number(num)
    num == num.to_i ? num.to_i.to_s : num.to_s
  end
end
