# frozen_string_literal: true

begin
  require "aws-sdk-rekognition"
rescue LoadError
  # AWS SDK will be loaded when the gem is installed
end

module Moderation
  module Providers
    # AWS Rekognition provider for content moderation.
    # Uses DetectModerationLabels API to analyze images for inappropriate content.
    #
    # @example Usage
    #   provider = RekognitionProvider.new
    #   result = provider.analyze(entry.photo)
    #   if result.violation_detected?
    #     puts "Detected: #{result.labels}"
    #   end
    #
    class RekognitionProvider < BaseProvider
      class ConfigurationError < StandardError; end
      class AnalysisError < StandardError; end

      LabelResult = Struct.new(:labels, :raw_response, keyword_init: true)

      def name
        "rekognition"
      end

      # Detects labels in an image using Rekognition DetectLabels API
      # @param attachment [ActiveStorage::Attached] the image attachment to analyze
      # @return [LabelResult] the detected labels
      # @raise [AnalysisError] if the API call fails
      def detect_labels(attachment)
        image_bytes = download_attachment(attachment)
        response = client.detect_labels(
          image: { bytes: image_bytes },
          max_labels: 20,
          min_confidence: 70.0
        )
        parse_labels_response(response)
      rescue Aws::Rekognition::Errors::ServiceError => e
        raise AnalysisError, "Rekognition detect_labels error: #{e.message}"
      rescue Aws::Errors::MissingCredentialsError => e
        raise ConfigurationError, "AWS credentials not configured: #{e.message}"
      end

      # Analyzes an image attachment for moderation labels
      # @param attachment [ActiveStorage::Attached] the image attachment to analyze
      # @return [Result] the analysis result
      # @raise [AnalysisError] if the API call fails
      def analyze(attachment)
        image_bytes = download_attachment(attachment)
        response = call_rekognition_api(image_bytes)
        parse_response(response)
      rescue Aws::Rekognition::Errors::ServiceError => e
        raise AnalysisError, "Rekognition API error: #{e.message}"
      rescue Aws::Errors::MissingCredentialsError => e
        raise ConfigurationError, "AWS credentials not configured: #{e.message}"
      end

      private

      def client
        @client ||= Aws::Rekognition::Client.new(client_options)
      end

      def client_options
        options = {}

        # Use configured region or default to ap-northeast-1 (Tokyo)
        options[:region] = aws_region

        # Allow explicit credentials configuration for testing/development
        if aws_credentials_configured?
          options[:access_key_id] = ENV["AWS_ACCESS_KEY_ID"]
          options[:secret_access_key] = ENV["AWS_SECRET_ACCESS_KEY"]
        end

        options
      end

      def aws_region
        ENV.fetch("AWS_REGION", "ap-northeast-1")
      end

      def aws_credentials_configured?
        ENV["AWS_ACCESS_KEY_ID"].present? && ENV["AWS_SECRET_ACCESS_KEY"].present?
      end

      def call_rekognition_api(image_bytes)
        client.detect_moderation_labels(
          image: { bytes: image_bytes },
          min_confidence: min_confidence_threshold
        )
      end

      def min_confidence_threshold
        # Use a lower threshold for API calls to get more labels,
        # actual filtering will be done based on contest threshold
        30.0
      end

      def parse_response(response)
        labels = extract_labels(response.moderation_labels)
        max_confidence = calculate_max_confidence(labels)

        Result.new(
          labels: labels,
          max_confidence: max_confidence,
          raw_response: serialize_response(response)
        )
      end

      def extract_labels(moderation_labels)
        moderation_labels.map do |label|
          {
            "Name" => label.name,
            "Confidence" => label.confidence.round(2),
            "ParentName" => label.parent_name
          }
        end
      end

      def calculate_max_confidence(labels)
        return nil if labels.empty?

        labels.map { |l| l["Confidence"] }.max
      end

      def parse_labels_response(response)
        labels = response.labels.map do |label|
          {
            "Name" => label.name,
            "Confidence" => label.confidence.round(2),
            "Categories" => label.respond_to?(:categories) ? label.categories&.map(&:name) : [],
            "Parents" => label.respond_to?(:parents) ? label.parents&.map(&:name) : []
          }
        end

        LabelResult.new(
          labels: labels,
          raw_response: {
            "Labels" => labels,
            "LabelModelVersion" => response.respond_to?(:label_model_version) ? response.label_model_version : nil
          }
        )
      end

      def serialize_response(response)
        {
          "ModerationLabels" => response.moderation_labels.map do |label|
            {
              "Name" => label.name,
              "Confidence" => label.confidence,
              "ParentName" => label.parent_name,
              "TaxonomyLevel" => label.taxonomy_level
            }
          end,
          "ModerationModelVersion" => response.moderation_model_version,
          "ContentTypes" => response.content_types&.map do |ct|
            { "Confidence" => ct.confidence, "Name" => ct.name }
          end
        }
      end
    end

    # Register the provider
    register(:rekognition, RekognitionProvider)
  end
end
