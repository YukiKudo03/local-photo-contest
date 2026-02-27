# frozen_string_literal: true

# Configure Capybara to use Japanese locale for system tests
# Headless Chrome defaults to Accept-Language: en-US, which causes
# the ApplicationController's set_locale to pick English instead of Japanese.
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--disable-gpu")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--accept-lang=ja")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end
