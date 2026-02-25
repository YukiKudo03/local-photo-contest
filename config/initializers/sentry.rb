# frozen_string_literal: true

if ENV["SENTRY_DSN"].present?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]

    # Set traces_sample_rate to capture performance data
    # 0.5 means 50% of transactions will be captured
    config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", "0.5").to_f

    # Enable breadcrumbs for better context
    config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

    # Set the environment
    config.environment = Rails.env

    # Set the release version
    config.release = "local-photo-contest@#{ENV.fetch('APP_VERSION', '1.0.0')}"

    # Add user context automatically
    config.before_send = lambda do |event, hint|
      # Filter out 404 errors
      if hint[:exception]&.is_a?(ActiveRecord::RecordNotFound)
        return nil
      end

      # Filter out routing errors
      if hint[:exception]&.is_a?(ActionController::RoutingError)
        return nil
      end

      event
    end

    # Exclude certain exceptions from being reported
    config.excluded_exceptions += [
      "ActionController::InvalidAuthenticityToken",
      "ActionController::BadRequest",
      "ActionDispatch::Http::Parameters::ParseError"
    ]

    # Performance monitoring settings
    config.profiles_sample_rate = ENV.fetch("SENTRY_PROFILES_SAMPLE_RATE", "0.1").to_f
  end

  # Add user context to Sentry events
  Rails.application.config.to_prepare do
    ApplicationController.class_eval do
      before_action :set_sentry_user_context

      private

      def set_sentry_user_context
        if current_user
          Sentry.set_user(
            id: current_user.id,
            email: current_user.email,
            username: current_user.name
          )
        end
      end
    end
  end
end
