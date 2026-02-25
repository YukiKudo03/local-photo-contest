# frozen_string_literal: true

Rails.application.configure do
  # Enable Lograge for structured logging in production
  config.lograge.enabled = Rails.env.production?

  # Use JSON format for better parsing by log aggregators
  config.lograge.formatter = Lograge::Formatters::Json.new

  # Include custom fields in log output
  config.lograge.custom_options = lambda do |event|
    exceptions = %w[controller action format id]
    options = {
      time: Time.current.iso8601,
      request_id: event.payload[:request_id],
      remote_ip: event.payload[:remote_ip],
      host: event.payload[:host]
    }

    # Add user information if available
    if event.payload[:user_id]
      options[:user_id] = event.payload[:user_id]
    end

    # Add request parameters (filtered for sensitive data)
    options[:params] = event.payload[:params]
                           .except(*exceptions)
                           .reject { |_k, v| v.blank? }

    # Add error information if present
    if event.payload[:exception_object]
      options[:exception] = {
        class: event.payload[:exception_object].class.name,
        message: event.payload[:exception_object].message
      }
    end

    options
  end

  # Add custom payload to log events
  config.lograge.custom_payload do |controller|
    {
      host: controller.request.host,
      remote_ip: controller.request.remote_ip,
      user_id: controller.respond_to?(:current_user) && controller.current_user&.id,
      request_id: controller.request.request_id
    }
  end
end
