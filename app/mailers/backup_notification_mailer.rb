# frozen_string_literal: true

class BackupNotificationMailer < ApplicationMailer
  def backup_completed(backup_record)
    @backup_record = backup_record

    mail(
      to: notify_emails,
      subject: t("backup.mailer.backup_completed.subject")
    )
  end

  def backup_failed(backup_record)
    @backup_record = backup_record

    mail(
      to: notify_emails,
      subject: t("backup.mailer.backup_failed.subject")
    )
  end

  def storage_maintenance_report(integrity_result, cleanup_result)
    @integrity_result = integrity_result
    @cleanup_result = cleanup_result

    mail(
      to: notify_emails,
      subject: t("backup.mailer.storage_maintenance_report.subject")
    )
  end

  private

  def notify_emails
    if ENV["BACKUP_NOTIFY_EMAILS"].present?
      ENV["BACKUP_NOTIFY_EMAILS"].split(",").map(&:strip)
    else
      User.where(role: :admin).pluck(:email)
    end
  end
end
