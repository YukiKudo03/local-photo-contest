class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_locale

  private

  def set_locale
    I18n.locale = params[:locale] || session[:locale] || current_user_locale || extract_locale_from_accept_language_header || I18n.default_locale
    session[:locale] = I18n.locale
  end

  def current_user_locale
    return nil unless user_signed_in? && current_user.locale.present?

    locale = current_user.locale
    I18n.available_locales.map(&:to_s).include?(locale) ? locale : nil
  end

  def extract_locale_from_accept_language_header
    return nil unless request.env["HTTP_ACCEPT_LANGUAGE"]

    accepted = request.env["HTTP_ACCEPT_LANGUAGE"].scan(/[a-z]{2}/).first
    I18n.available_locales.map(&:to_s).include?(accepted) ? accepted : nil
  end

  def default_url_options
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  end
end
