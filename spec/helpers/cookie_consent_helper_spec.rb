# frozen_string_literal: true

require "rails_helper"

RSpec.describe CookieConsentHelper, type: :helper do
  describe "#cookie_consent_given?" do
    it "returns true when cookie_consent cookie is present" do
      helper.request.cookies["cookie_consent"] = "all"
      expect(helper.cookie_consent_given?).to be true
    end

    it "returns false when cookie_consent cookie is absent" do
      expect(helper.cookie_consent_given?).to be false
    end
  end

  describe "#analytics_cookies_accepted?" do
    it "returns true when consent is 'all'" do
      helper.request.cookies["cookie_consent"] = "all"
      expect(helper.analytics_cookies_accepted?).to be true
    end

    it "returns false when consent is 'essential'" do
      helper.request.cookies["cookie_consent"] = "essential"
      expect(helper.analytics_cookies_accepted?).to be false
    end

    it "returns false when no consent cookie exists" do
      expect(helper.analytics_cookies_accepted?).to be false
    end
  end
end
