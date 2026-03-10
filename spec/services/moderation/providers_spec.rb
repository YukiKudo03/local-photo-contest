# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::Providers, type: :service do
  describe ".current" do
    context "when no provider is configured" do
      before do
        allow(described_class).to receive(:config).and_return(nil)
      end

      it "raises ProviderNotConfiguredError" do
        expect { described_class.current }.to raise_error(Moderation::Providers::ProviderNotConfiguredError)
      end
    end

    context "when provider is configured but not registered" do
      before do
        config = ActiveSupport::OrderedOptions.new
        config.provider = :nonexistent
        config.enabled = true
        allow(described_class).to receive(:config).and_return(config)
      end

      it "raises ProviderNotRegisteredError" do
        expect { described_class.current }.to raise_error(Moderation::Providers::ProviderNotRegisteredError)
      end
    end
  end

  describe ".enabled?" do
    context "when config is nil" do
      before { allow(described_class).to receive(:config).and_return(nil) }

      it "returns true" do
        expect(described_class.enabled?).to be true
      end
    end

    context "when config.enabled is false" do
      before do
        config = ActiveSupport::OrderedOptions.new
        config.enabled = false
        allow(described_class).to receive(:config).and_return(config)
      end

      it "returns false" do
        expect(described_class.enabled?).to be false
      end
    end
  end

  describe ".default_threshold" do
    context "when config is nil" do
      before { allow(described_class).to receive(:config).and_return(nil) }

      it "returns 60.0" do
        expect(described_class.default_threshold).to eq(60.0)
      end
    end

    context "when config has custom threshold" do
      before do
        config = ActiveSupport::OrderedOptions.new
        config.default_threshold = 75.0
        allow(described_class).to receive(:config).and_return(config)
      end

      it "returns the custom threshold" do
        expect(described_class.default_threshold).to eq(75.0)
      end
    end
  end

  describe ".registered" do
    it "returns list of registered provider names" do
      described_class.load_providers!
      result = described_class.registered
      expect(result).to be_an(Array)
      expect(result).to include(:rekognition)
    end
  end

  describe ".config" do
    context "when moderation config is not set on application" do
      before do
        allow(Rails.application.config).to receive(:respond_to?).with(:moderation).and_return(false)
      end

      it "returns nil" do
        expect(described_class.config).to be_nil
      end
    end
  end
end
