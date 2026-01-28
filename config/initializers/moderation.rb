# frozen_string_literal: true

# Content Moderation Configuration
#
# This initializer configures the content moderation system used to automatically
# detect inappropriate content in uploaded photos.
#
# == Environment Variables
#
# AWS_ACCESS_KEY_ID     - AWS access key (required for Rekognition)
# AWS_SECRET_ACCESS_KEY - AWS secret key (required for Rekognition)
# AWS_REGION            - AWS region (defaults to ap-northeast-1)
# MODERATION_PROVIDER   - Provider name (defaults to :rekognition)
# MODERATION_ENABLED    - Enable/disable moderation globally (defaults to true)
# MODERATION_THRESHOLD  - Default confidence threshold 0-100 (defaults to 60.0)
#
# == Setup Instructions
#
# 1. Create an AWS IAM user with the following permissions:
#    - rekognition:DetectModerationLabels
#
# 2. Set the environment variables:
#    export AWS_ACCESS_KEY_ID=your_access_key
#    export AWS_SECRET_ACCESS_KEY=your_secret_key
#    export AWS_REGION=ap-northeast-1
#
# 3. Or use Rails credentials:
#    rails credentials:edit
#
#    aws:
#      access_key_id: your_access_key
#      secret_access_key: your_secret_key
#      region: ap-northeast-1
#
# == Testing
#
# In test environment, moderation is disabled by default.
# Use mocks in your specs instead of calling the real API.

Rails.application.config.moderation = ActiveSupport::OrderedOptions.new

Rails.application.config.moderation.tap do |config|
  # Provider to use for moderation (currently only :rekognition is supported)
  config.provider = ENV.fetch("MODERATION_PROVIDER", "rekognition").to_sym

  # Whether moderation is globally enabled
  # Individual contests can still disable moderation even when this is true
  config.enabled = ActiveModel::Type::Boolean.new.cast(
    ENV.fetch("MODERATION_ENABLED", "true")
  )

  # Default confidence threshold (0-100)
  # Labels with confidence below this threshold will require manual review
  # Labels at or above this threshold will automatically hide the entry
  config.default_threshold = ENV.fetch("MODERATION_THRESHOLD", "60.0").to_f
end

# Load provider classes to register them with the Providers module
# This must happen after Rails is fully initialized
Rails.application.config.after_initialize do
  Moderation::Providers.load_providers! if defined?(Moderation::Providers)
end
