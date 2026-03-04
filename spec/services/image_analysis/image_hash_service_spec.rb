# frozen_string_literal: true

require "rails_helper"

RSpec.describe ImageAnalysis::ImageHashService, type: :service do
  let(:entry) { create(:entry) }
  let(:service) { described_class.new(entry) }

  describe "#generate_hash" do
    it "generates a hash string and saves it to the entry" do
      result = service.generate_hash
      entry.reload
      expect(entry.image_hash).to be_present
      expect(entry.image_hash.length).to eq(16)
    end

    it "returns the hash value" do
      result = service.generate_hash
      expect(result).to be_a(String)
      expect(result.length).to eq(16)
    end

    context "without attached photo" do
      let(:entry) { build(:entry, :without_photo) }

      before do
        allow(entry).to receive(:persisted?).and_return(true)
      end

      it "returns nil" do
        expect(service.generate_hash).to be_nil
      end
    end
  end

  describe "#find_similar" do
    let!(:entry1) { create(:entry, image_hash: "0000000000000000") }
    let!(:entry2) { create(:entry, image_hash: "0000000000000001") }  # distance 1
    let!(:entry3) { create(:entry, image_hash: "ffffffffffffffff") }  # very different

    let(:service) { described_class.new(entry1) }

    it "finds entries within threshold" do
      similar = service.find_similar(threshold: 5)
      expect(similar).to include(entry2)
      expect(similar).not_to include(entry3)
    end

    it "does not include self" do
      similar = service.find_similar(threshold: 100)
      expect(similar).not_to include(entry1)
    end

    it "respects limit" do
      similar = service.find_similar(threshold: 100, limit: 1)
      expect(similar.size).to eq(1)
    end

    context "when entry has no image_hash" do
      let(:entry_no_hash) { create(:entry, image_hash: nil) }
      let(:service) { described_class.new(entry_no_hash) }

      it "returns empty array" do
        expect(service.find_similar).to eq([])
      end
    end
  end

  describe ".hamming_distance" do
    it "returns 0 for identical hashes" do
      expect(described_class.hamming_distance("abcdef0123456789", "abcdef0123456789")).to eq(0)
    end

    it "counts differing bits" do
      # 0x0 = 0000, 0x1 = 0001 → 1 bit difference
      expect(described_class.hamming_distance("0000000000000000", "0000000000000001")).to eq(1)
    end

    it "returns maximum for completely different hashes" do
      distance = described_class.hamming_distance("0000000000000000", "ffffffffffffffff")
      expect(distance).to eq(64)
    end

    it "returns Infinity for nil hashes" do
      expect(described_class.hamming_distance(nil, "abc")).to eq(Float::INFINITY)
      expect(described_class.hamming_distance("abc", nil)).to eq(Float::INFINITY)
    end
  end
end
