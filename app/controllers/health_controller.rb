# frozen_string_literal: true

class HealthController < ApplicationController
  # Skip authentication for health checks
  skip_before_action :authenticate_user!, raise: false

  def show
    health_status = check_health

    status = health_status[:status] == "ok" ? :ok : :service_unavailable
    render json: health_status, status: status
  end

  def details
    render json: detailed_health_status
  end

  private

  def check_health
    database_status = check_database

    {
      status: database_status == "ok" ? "ok" : "error",
      database: database_status,
      timestamp: Time.current.iso8601
    }
  end

  def detailed_health_status
    {
      status: "ok",
      database: database_details,
      cache: cache_details,
      version: app_version,
      timestamp: Time.current.iso8601,
      environment: Rails.env
    }
  end

  def check_database
    ActiveRecord::Base.connection.execute("SELECT 1")
    "ok"
  rescue StandardError
    "error"
  end

  def database_details
    {
      connected: database_connected?,
      adapter: ActiveRecord::Base.connection.adapter_name,
      pool_size: ActiveRecord::Base.connection_pool.size,
      active_connections: ActiveRecord::Base.connection_pool.connections.count
    }
  rescue StandardError => e
    {
      connected: false,
      error: e.message
    }
  end

  def database_connected?
    ActiveRecord::Base.connection.active?
  rescue StandardError
    false
  end

  def cache_details
    cache_class = Rails.cache.class.name
    cache_healthy = test_cache_connection

    {
      type: cache_class,
      healthy: cache_healthy
    }
  end

  def test_cache_connection
    key = "health_check_#{SecureRandom.hex(4)}"
    Rails.cache.write(key, "test", expires_in: 1.second)
    result = Rails.cache.read(key) == "test"
    Rails.cache.delete(key)
    result
  rescue StandardError
    false
  end

  def app_version
    ENV.fetch("APP_VERSION", "1.0.0")
  end
end
