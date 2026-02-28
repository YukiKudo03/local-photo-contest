# frozen_string_literal: true

module CookieConsentHelper
  def cookie_consent_given?
    cookies["cookie_consent"].present?
  end

  def analytics_cookies_accepted?
    cookies["cookie_consent"] == "all"
  end
end
