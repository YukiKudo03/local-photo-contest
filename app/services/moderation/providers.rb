# frozen_string_literal: true

module Moderation
  # Registry and factory for content moderation providers.
  # Providers are registered in their respective files and loaded via Rails autoloading.
  # Provides a centralized way to register and retrieve provider instances.
  #
  # @example Configuration in config/initializers/moderation.rb
  #   Rails.application.config.moderation = ActiveSupport::OrderedOptions.new
  #   Rails.application.config.moderation.provider = :rekognition
  #   Rails.application.config.moderation.enabled = true
  #   Rails.application.config.moderation.default_threshold = 60.0
  #
  # @example Getting the current provider
  #   provider = Moderation::Providers.current
  #   result = provider.analyze(entry.photo)
  #
  module Providers
    class ProviderNotRegisteredError < StandardError; end
    class ProviderNotConfiguredError < StandardError; end

    class << self
      # Returns the currently configured provider instance
      # @return [BaseProvider] the provider instance
      # @raise [ProviderNotConfiguredError] if no provider is configured
      # @raise [ProviderNotRegisteredError] if the configured provider is not registered
      def current
        provider_name = configured_provider_name
        raise ProviderNotConfiguredError, "No moderation provider configured" unless provider_name

        get(provider_name)
      end

      # Gets a provider by name
      # @param name [Symbol, String] the provider name
      # @return [BaseProvider] the provider instance
      # @raise [ProviderNotRegisteredError] if the provider is not registered
      def get(name)
        provider_class = registry[name.to_sym]
        raise ProviderNotRegisteredError, "Provider '#{name}' is not registered" unless provider_class

        provider_class.new
      end

      # Registers a provider class
      # @param name [Symbol] the provider name
      # @param klass [Class] the provider class
      def register(name, klass)
        registry[name.to_sym] = klass
      end

      # Returns all registered provider names
      # @return [Array<Symbol>] the registered provider names
      def registered
        registry.keys
      end

      # Checks if a provider is registered
      # @param name [Symbol, String] the provider name
      # @return [Boolean] true if registered
      def registered?(name)
        registry.key?(name.to_sym)
      end

      # Returns the global moderation configuration
      # @return [ActiveSupport::OrderedOptions, nil] the configuration
      def config
        return nil unless Rails.application.config.respond_to?(:moderation)

        Rails.application.config.moderation
      end

      # Checks if moderation is globally enabled
      # @return [Boolean] true if enabled (defaults to true if not configured)
      def enabled?
        return true if config.nil?

        config.enabled != false
      end

      # Returns the default threshold from configuration
      # @return [Float] the default threshold (defaults to 60.0)
      def default_threshold
        config&.default_threshold || 60.0
      end

      # Eagerly load all provider classes to ensure registration
      # Called from initializer
      def load_providers!
        Dir[File.join(__dir__, "providers", "*.rb")].each do |file|
          require file unless file.end_with?("base_provider.rb")
        end
      end

      private

      def registry
        @registry ||= {}
      end

      def configured_provider_name
        config&.provider
      end
    end
  end
end
