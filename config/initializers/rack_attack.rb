# frozen_string_literal: true

class Rack::Attack
  ### Configure Cache ###

  # Use Rails cache for storing throttle data (Redis in production)
  Rack::Attack.cache.store = Rails.cache

  ### Throttle Spammy Clients ###

  # Throttle all requests by IP (300 requests per 5 minutes)
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  ### Prevent Brute-Force Login Attacks ###

  # Throttle POST requests to /users/sign_in by IP address
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  # Throttle POST requests to /users/sign_in by email
  throttle("logins/email", limit: 5, period: 20.seconds) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.params.dig("user", "email")&.downcase&.gsub(/\s+/, "")
    end
  end

  ### Throttle Spot Votes ###

  # Throttle POST requests to spot_votes by IP (10 per minute)
  throttle("spot_votes/ip", limit: 10, period: 1.minute) do |req|
    if req.path.match?(%r{/spots/\d+/vote}) && req.post?
      req.ip
    end
  end

  # Throttle POST requests to spot_votes by user (30 per hour)
  throttle("spot_votes/user", limit: 30, period: 1.hour) do |req|
    if req.path.match?(%r{/spots/\d+/vote}) && req.post?
      # Get user_id from session (requires Warden)
      req.env["warden"]&.user&.id
    end
  end

  ### Throttle Entry Votes ###

  # Throttle POST requests to entry votes by IP (20 per minute)
  throttle("entry_votes/ip", limit: 20, period: 1.minute) do |req|
    if req.path.match?(%r{/entries/\d+/vote}) && req.post?
      req.ip
    end
  end

  ### Throttle Entry Submissions ###

  # Throttle entry submissions by user (10 per hour)
  throttle("entries/user", limit: 10, period: 1.hour) do |req|
    if req.path.match?(%r{/contests/\d+/entries}) && req.post?
      req.env["warden"]&.user&.id
    end
  end

  ### Blocklist ###

  # Block requests containing potential attacks
  blocklist("block/sql_injection") do |req|
    Rack::Attack::Fail2Ban.filter("sql-injection-#{req.ip}", maxretry: 1, findtime: 1.hour, bantime: 1.day) do
      CGI.unescape(req.query_string).match?(/\b(UNION|SELECT|INSERT|DELETE|UPDATE|DROP|ALTER)\b/i)
    end
  end

  ### Custom Responses ###

  # Customize throttle response
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = Time.current

    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => (match_data[:period] - (now.to_i % match_data[:period])).to_s
      },
      [ { error: "リクエスト回数の制限に達しました。しばらく時間をおいてから再度お試しください。" }.to_json ]
    ]
  end
end

# Enable Rack::Attack in the middleware stack
Rails.application.config.middleware.use Rack::Attack
