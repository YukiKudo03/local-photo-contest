# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::Providers::RekognitionProvider, type: :service do
  let(:provider) { described_class.new }
  let(:entry) { create(:entry) }
  let(:image_bytes) { "fake image bytes" }

  # Mock AWS Rekognition response structures
  let(:moderation_label) do
    double(
      "ModerationLabel",
      name: "Explicit Nudity",
      confidence: 85.5,
      parent_name: "Nudity",
      taxonomy_level: 2
    )
  end

  let(:clean_response) do
    double(
      "DetectModerationLabelsResponse",
      moderation_labels: [],
      moderation_model_version: "7.0",
      content_types: nil
    )
  end

  let(:violation_response) do
    double(
      "DetectModerationLabelsResponse",
      moderation_labels: [ moderation_label ],
      moderation_model_version: "7.0",
      content_types: [ double("ContentType", name: "Photo", confidence: 99.0) ]
    )
  end

  before do
    # Stub the attachment download
    allow(entry.photo).to receive(:download).and_return(image_bytes)
    allow(entry.photo).to receive(:content_type).and_return("image/jpeg")
  end

  describe "#name" do
    it "returns 'rekognition'" do
      expect(provider.name).to eq("rekognition")
    end
  end

  describe "#analyze" do
    context "when AWS SDK is available", if: defined?(Aws::Rekognition) do
      let(:mock_client) { instance_double(Aws::Rekognition::Client) }

      before do
        allow(Aws::Rekognition::Client).to receive(:new).and_return(mock_client)
      end

      context "when no violations detected" do
        before do
          allow(mock_client).to receive(:detect_moderation_labels).and_return(clean_response)
        end

        it "returns result with empty labels" do
          result = provider.analyze(entry.photo)

          expect(result.labels).to eq([])
          expect(result.max_confidence).to be_nil
        end

        it "returns result that is not a violation" do
          result = provider.analyze(entry.photo)

          expect(result.violation_detected?).to be false
        end
      end

      context "when violations detected" do
        before do
          allow(mock_client).to receive(:detect_moderation_labels).and_return(violation_response)
        end

        it "returns result with labels" do
          result = provider.analyze(entry.photo)

          expect(result.labels).to be_present
          expect(result.labels.first["Name"]).to eq("Explicit Nudity")
        end

        it "calculates max confidence" do
          result = provider.analyze(entry.photo)

          expect(result.max_confidence).to eq(85.5)
        end

        it "marks as violation detected" do
          result = provider.analyze(entry.photo)

          expect(result.violation_detected?).to be true
        end

        it "stores raw response" do
          result = provider.analyze(entry.photo)

          expect(result.raw_response["ModerationLabels"]).to be_present
          expect(result.raw_response["ModerationModelVersion"]).to eq("7.0")
        end
      end

      context "when API error occurs" do
        before do
          allow(mock_client).to receive(:detect_moderation_labels)
            .and_raise(Aws::Rekognition::Errors::ServiceError.new(nil, "API Error"))
        end

        it "raises AnalysisError" do
          expect { provider.analyze(entry.photo) }
            .to raise_error(Moderation::Providers::RekognitionProvider::AnalysisError, /API Error/)
        end
      end

      context "when credentials not configured" do
        before do
          allow(mock_client).to receive(:detect_moderation_labels)
            .and_raise(Aws::Errors::MissingCredentialsError.new("Missing credentials"))
        end

        it "raises ConfigurationError" do
          expect { provider.analyze(entry.photo) }
            .to raise_error(Moderation::Providers::RekognitionProvider::ConfigurationError, /credentials/)
        end
      end
    end

    context "when AWS SDK is not available" do
      before do
        # Simulate AWS SDK not being loaded
        hide_const("Aws::Rekognition") if defined?(Aws::Rekognition)
      end

      it "is still loadable" do
        # The provider class should still be loadable even without the gem
        expect(defined?(Moderation::Providers::RekognitionProvider)).to be_truthy
      end
    end
  end

  describe "#detect_labels" do
    context "when AWS SDK is available", if: defined?(Aws::Rekognition) do
      let(:mock_client) { instance_double(Aws::Rekognition::Client) }
      let(:label) do
        double(
          "Label",
          name: "Mountain",
          confidence: 95.5,
          categories: [ double(name: "Nature") ],
          parents: [ double(name: "Outdoors") ]
        )
      end
      let(:labels_response) do
        double(
          "DetectLabelsResponse",
          labels: [ label ],
          label_model_version: "3.0"
        )
      end

      before do
        allow(Aws::Rekognition::Client).to receive(:new).and_return(mock_client)
      end

      context "when labels are detected" do
        before do
          allow(mock_client).to receive(:detect_labels).and_return(labels_response)
        end

        it "returns LabelResult with labels" do
          result = provider.detect_labels(entry.photo)

          expect(result).to be_a(described_class::LabelResult)
          expect(result.labels.size).to eq(1)
          expect(result.labels.first["Name"]).to eq("Mountain")
          expect(result.labels.first["Confidence"]).to eq(95.5)
        end

        it "includes categories and parents" do
          result = provider.detect_labels(entry.photo)

          expect(result.labels.first["Categories"]).to eq([ "Nature" ])
          expect(result.labels.first["Parents"]).to eq([ "Outdoors" ])
        end

        it "stores raw response" do
          result = provider.detect_labels(entry.photo)

          expect(result.raw_response["Labels"]).to be_present
        end
      end

      context "when API error occurs" do
        before do
          allow(mock_client).to receive(:detect_labels)
            .and_raise(Aws::Rekognition::Errors::ServiceError.new(nil, "API Error"))
        end

        it "raises AnalysisError" do
          expect { provider.detect_labels(entry.photo) }
            .to raise_error(described_class::AnalysisError, /detect_labels/)
        end
      end

      context "when credentials not configured" do
        before do
          allow(mock_client).to receive(:detect_labels)
            .and_raise(Aws::Errors::MissingCredentialsError.new("Missing credentials"))
        end

        it "raises ConfigurationError" do
          expect { provider.detect_labels(entry.photo) }
            .to raise_error(described_class::ConfigurationError, /credentials/)
        end
      end
    end
  end

  describe "registration" do
    it "is registered with the Providers module" do
      Moderation::Providers.load_providers!
      expect(Moderation::Providers.registered?(:rekognition)).to be true
    end

    it "can be retrieved by name" do
      Moderation::Providers.load_providers!
      expect(Moderation::Providers.get(:rekognition)).to be_a(described_class)
    end
  end

  describe "client_options with credentials", if: defined?(Aws::Rekognition) do
    it "includes credentials when AWS env vars are set" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("AWS_ACCESS_KEY_ID").and_return("test_key")
      allow(ENV).to receive(:[]).with("AWS_SECRET_ACCESS_KEY").and_return("test_secret")
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("AWS_REGION", "ap-northeast-1").and_return("us-east-1")

      # Instantiate provider - the client_options method is called internally
      new_provider = described_class.new
      expect(new_provider).to be_a(described_class)
    end

    it "sets access_key_id and secret_access_key in client_options" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("AWS_ACCESS_KEY_ID").and_return("test_key")
      allow(ENV).to receive(:[]).with("AWS_SECRET_ACCESS_KEY").and_return("test_secret")
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("AWS_REGION", "ap-northeast-1").and_return("us-east-1")

      new_provider = described_class.new
      options = new_provider.send(:client_options)
      expect(options[:access_key_id]).to eq("test_key")
      expect(options[:secret_access_key]).to eq("test_secret")
    end
  end
end
