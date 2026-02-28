# frozen_string_literal: true

class UserDataPurgeService
  def initialize(user, mode: :delete)
    @user = user
    @mode = mode
  end

  def purge!
    case @mode
    when :delete
      full_delete!
    when :anonymize
      anonymize!
    end
  end

  private

  def full_delete!
    user_id = @user.id
    email_hash = Digest::SHA256.hexdigest(@user.email)

    # Remove audit logs referencing this user to avoid FK constraint on deletion
    AuditLog.where(user_id: user_id).delete_all

    @user.destroy!

    Rails.logger.info("Account data purged: user_id=#{user_id}, mode=delete, email_hash=#{email_hash}")
  end

  def anonymize!
    @user.comments.destroy_all
    @user.notifications.destroy_all
    @user.terms_acceptances.destroy_all
    @user.data_export_requests.destroy_all

    @user.avatar.purge if @user.avatar.attached?

    @user.update_columns(
      email: "deleted_#{@user.id}@deleted.example.com",
      name: "Deleted User",
      bio: nil,
      encrypted_password: SecureRandom.hex(32),
      current_sign_in_at: nil,
      last_sign_in_at: nil,
      current_sign_in_ip: nil,
      last_sign_in_ip: nil,
      sign_in_count: 0,
      deletion_requested_at: nil,
      deletion_scheduled_at: nil
    )
    @user.reload

    AuditLog.log(
      action: "account_data_purged",
      user: @user,
      details: { user_id: @user.id, mode: "anonymize" }
    )
  end
end
