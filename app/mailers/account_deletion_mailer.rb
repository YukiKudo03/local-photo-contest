# frozen_string_literal: true

class AccountDeletionMailer < ApplicationMailer
  def deletion_requested(user)
    @user = user
    @days_until_deletion = user.days_until_deletion

    @unsubscribe_url = unsubscribe_url_for(@user)
    I18n.with_locale(@user.locale || I18n.default_locale) do
      mail(to: @user.email, subject: t("gdpr.account_deletion.mailer.requested.subject"))
    end
  end

  def deletion_reminder(user)
    @user = user
    @days_until_deletion = user.days_until_deletion

    @unsubscribe_url = unsubscribe_url_for(@user)
    I18n.with_locale(@user.locale || I18n.default_locale) do
      mail(to: @user.email, subject: t("gdpr.account_deletion.mailer.reminder.subject"))
    end
  end

  def deletion_completed(user)
    @user = user

    I18n.with_locale(@user.locale || I18n.default_locale) do
      mail(to: @user.email, subject: t("gdpr.account_deletion.mailer.completed.subject"))
    end
  end

  def deletion_cancelled(user)
    @user = user

    @unsubscribe_url = unsubscribe_url_for(@user)
    I18n.with_locale(@user.locale || I18n.default_locale) do
      mail(to: @user.email, subject: t("gdpr.account_deletion.mailer.cancelled.subject"))
    end
  end
end
