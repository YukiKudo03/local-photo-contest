# frozen_string_literal: true

# CORS configuration for API endpoints
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*"

    resource "/api/*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      expose: [ "X-Total-Count", "X-Total-Pages", "X-Current-Page", "X-Per-Page" ]
  end
end
