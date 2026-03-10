# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::Providers::BaseProvider do
  subject(:provider) { described_class.new }

  describe "#name" do
    it "raises NotImplementedError" do
      expect { provider.name }.to raise_error(NotImplementedError, /must implement #name/)
    end
  end

  describe "#analyze" do
    it "raises NotImplementedError" do
      expect { provider.analyze(double("attachment")) }.to raise_error(NotImplementedError, /must implement #analyze/)
    end
  end

  describe "#download_attachment" do
    it "calls download on the attachment" do
      attachment = double("attachment", download: "binary content")
      result = provider.send(:download_attachment, attachment)
      expect(result).to eq("binary content")
    end
  end

  describe "#content_type" do
    it "returns the content type of the attachment" do
      attachment = double("attachment", content_type: "image/jpeg")
      result = provider.send(:content_type, attachment)
      expect(result).to eq("image/jpeg")
    end
  end

  describe "Result" do
    it "detects violations when labels are present" do
      result = described_class::Result.new(labels: ["nudity"], max_confidence: 0.95, raw_response: {})
      expect(result.violation_detected?).to be true
    end

    it "does not detect violations when labels are empty" do
      result = described_class::Result.new(labels: [], max_confidence: nil, raw_response: {})
      expect(result.violation_detected?).to be false
    end

    it "does not detect violations when labels are nil" do
      result = described_class::Result.new(labels: nil, max_confidence: nil, raw_response: {})
      expect(result.violation_detected?).to be false
    end
  end
end
