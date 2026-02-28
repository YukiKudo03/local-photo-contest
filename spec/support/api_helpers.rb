# frozen_string_literal: true

module ApiHelpers
  def api_headers(token: nil, content_type: "application/json")
    headers = { "Accept" => "application/json" }
    headers["Content-Type"] = content_type if content_type
    headers["Authorization"] = "Bearer #{token}" if token
    headers
  end

  def json_response
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request, file_path: %r{spec/requests/api}
end
