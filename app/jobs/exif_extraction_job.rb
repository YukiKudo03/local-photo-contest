# frozen_string_literal: true

class ExifExtractionJob < ApplicationJob
  queue_as :default

  EXIF_FIELDS = %w[
    DateTimeOriginal
    GPSLatitude GPSLatitudeRef
    GPSLongitude GPSLongitudeRef
    Make Model
    FNumber ExposureTime ISOSpeedRatings FocalLength
  ].freeze

  def perform(entry_id)
    entry = Entry.find_by(id: entry_id)
    return unless entry&.photo&.attached?

    entry.photo.open do |tempfile|
      image = MiniMagick::Image.new(tempfile.path)
      exif = extract_exif(image)
      return if exif.blank?

      entry.update_columns(
        exif_data: exif,
        **auto_fill_fields(entry, exif)
      )
    end
  rescue MiniMagick::Error => e
    Rails.logger.error("EXIF extraction failed for entry #{entry_id}: #{e.message}")
  end

  private

  def extract_exif(image)
    raw = image.exif
    return {} if raw.blank?

    raw.slice(*EXIF_FIELDS).compact_blank
  end

  def auto_fill_fields(entry, exif)
    fields = {}

    if entry.taken_at.blank? && exif["DateTimeOriginal"].present?
      date = parse_exif_date(exif["DateTimeOriginal"])
      fields[:taken_at] = date if date
    end

    if entry.latitude.blank? && exif["GPSLatitude"].present?
      lat = convert_gps_coordinate(exif["GPSLatitude"], exif["GPSLatitudeRef"])
      lon = convert_gps_coordinate(exif["GPSLongitude"], exif["GPSLongitudeRef"])
      if lat && lon
        fields[:latitude] = lat
        fields[:longitude] = lon
        fields[:location_source] = Entry.location_sources[:exif]
      end
    end

    fields
  end

  def parse_exif_date(date_str)
    Date.strptime(date_str, "%Y:%m:%d %H:%M:%S")
  rescue Date::Error, ArgumentError
    nil
  end

  def convert_gps_coordinate(dms_string, ref)
    return nil if dms_string.blank?

    parts = dms_string.split(", ").map { |p| Rational(p).to_f }
    return nil unless parts.size == 3

    decimal = parts[0] + (parts[1] / 60.0) + (parts[2] / 3600.0)
    decimal *= -1 if ref&.match?(/[SW]/i)
    decimal.round(7)
  end
end
