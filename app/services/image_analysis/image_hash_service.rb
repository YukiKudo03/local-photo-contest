# frozen_string_literal: true

begin
  require "mini_magick"
rescue LoadError
  # MiniMagick will be loaded when the gem is installed
end

module ImageAnalysis
  class ImageHashService
    DEFAULT_THRESHOLD = 10
    DEFAULT_LIMIT = 10

    def initialize(entry)
      @entry = entry
    end

    def generate_hash
      return unless @entry.photo.attached?
      return unless defined?(MiniMagick)

      @entry.photo.open do |tempfile|
        hash_value = compute_dhash(tempfile.path)
        @entry.update_columns(image_hash: hash_value)
        hash_value
      end
    rescue StandardError => e
      Rails.logger.error("ImageHashService: Error for entry #{@entry.id}: #{e.message}")
      nil
    end

    def find_similar(threshold: DEFAULT_THRESHOLD, limit: DEFAULT_LIMIT)
      return [] unless @entry.image_hash.present?

      candidates = Entry.where.not(image_hash: nil)
                        .where.not(id: @entry.id)
                        .pluck(:id, :image_hash)

      similar = candidates.filter_map do |id, hash|
        distance = self.class.hamming_distance(@entry.image_hash, hash)
        { id: id, distance: distance } if distance <= threshold
      end

      similar.sort_by { |s| s[:distance] }
             .first(limit)
             .map { |s| Entry.find(s[:id]) }
    end

    def self.hamming_distance(hash1, hash2)
      return Float::INFINITY if hash1.nil? || hash2.nil?

      val1 = hash1.to_i(16)
      val2 = hash2.to_i(16)
      xor = val1 ^ val2

      # Popcount: count number of set bits
      count = 0
      while xor > 0
        count += xor & 1
        xor >>= 1
      end
      count
    end

    private

    def compute_dhash(image_path)
      # Resize to 9x8 grayscale and extract pixel values via text format
      pixel_text = MiniMagick.convert do |convert|
        convert << image_path
        convert.colorspace("Gray")
        convert.resize("9x8!")
        convert.depth(8)
        convert << "txt:-"
      end

      pixels = parse_pixel_text(pixel_text)

      # Compute difference hash: compare adjacent horizontal pixels
      bits = []
      8.times do |row|
        8.times do |col|
          left = pixels[row * 9 + col] || 128
          right = pixels[row * 9 + col + 1] || 128
          bits << (left < right ? 1 : 0)
        end
      end

      # Convert 64 bits to 16-char hex string
      bits.each_slice(4).map { |nibble| nibble.join.to_i(2).to_s(16) }.join
    end

    def parse_pixel_text(text)
      # ImageMagick txt:- format outputs lines like:
      # 0,0: (128)  #808080  gray(128)
      text.each_line.filter_map do |line|
        next if line.start_with?("#") # Skip header

        match = line.match(/\((\d+)/)
        match[1].to_i if match
      end
    end
  end
end
