# frozen_string_literal: true

# Ensure routes are loaded before Devise helpers are used
# This fixes the "Could not find a valid mapping" error when running single spec files
Rails.application.reload_routes!

RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Warden::Test::Helpers, type: :system

  config.after(type: :system) do
    Warden.test_reset!
  end
end
