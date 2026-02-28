# frozen_string_literal: true

class My::AccountDeletionsController < ApplicationController
  before_action :authenticate_user!

  def new
    @deletion_requested = current_user.deletion_requested?
  end

  def create
    unless current_user.valid_password?(params[:password])
      redirect_to new_my_account_deletion_path, alert: t("gdpr.account_deletion.wrong_password")
      return
    end

    current_user.request_deletion!
    AuditLog.log(action: "account_deletion_requested", user: current_user)
    AccountDeletionMailer.deletion_requested(current_user).deliver_later
    redirect_to my_profile_path, notice: t("gdpr.account_deletion.requested")
  end

  def destroy
    current_user.cancel_deletion!
    AuditLog.log(action: "account_deletion_cancelled", user: current_user)
    AccountDeletionMailer.deletion_cancelled(current_user).deliver_later
    redirect_to my_profile_path, notice: t("gdpr.account_deletion.cancelled")
  end
end
