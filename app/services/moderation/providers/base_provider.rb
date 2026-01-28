# frozen_string_literal: true

module Moderation
  module Providers
    # Abstract base class for content moderation providers.
    # Subclasses must implement the #analyze method.
    #
    # @example
    #   class CustomProvider < BaseProvider
    #     def name
    #       "custom"
    #     end
    #
    #     def analyze(attachment)
    #       # Perform moderation analysis
    #       Result.new(labels: [], max_confidence: nil, raw_response: {})
    #     end
    #   end
    #
    class BaseProvider
      # Standardized result object returned from analyze method
      Result = Struct.new(:labels, :max_confidence, :raw_response, keyword_init: true) do
        def violation_detected?
          labels.present? && labels.any?
        end
      end

      # Returns the provider name identifier
      # @return [String] the provider name
      def name
        raise NotImplementedError, "#{self.class} must implement #name"
      end

      # Analyzes an attachment for content violations
      # @param attachment [ActiveStorage::Attached] the attachment to analyze
      # @return [Result] the analysis result
      def analyze(attachment)
        raise NotImplementedError, "#{self.class} must implement #analyze"
      end

      protected

      # Downloads attachment content for analysis
      # @param attachment [ActiveStorage::Attached] the attachment to download
      # @return [String] the binary content
      def download_attachment(attachment)
        attachment.download
      end

      # Gets the content type of the attachment
      # @param attachment [ActiveStorage::Attached] the attachment
      # @return [String] the content type
      def content_type(attachment)
        attachment.content_type
      end
    end
  end
end
