# frozen_string_literal: true

class DataExportMailer < ApplicationMailer
  def export_ready(export_request)
    @user = export_request.user
    @export_request = export_request
    @days_until_expiry = ((export_request.expires_at - Time.current) / 1.day).ceil

    @unsubscribe_url = unsubscribe_url_for(@user)
    I18n.with_locale(@user.locale || I18n.default_locale) do
      mail(to: @user.email, subject: t("gdpr.data_export.mailer.subject"))
    end
  end
end
