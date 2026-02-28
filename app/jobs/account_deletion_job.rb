# frozen_string_literal: true

class AccountDeletionJob < ApplicationJob
  queue_as :default

  def perform
    User.pending_deletion.find_each do |user|
      AccountDeletionMailer.deletion_completed(user).deliver_now
      UserDataPurgeService.new(user, mode: :delete).purge!
    rescue => e
      Rails.logger.error("Account deletion failed for user ##{user.id}: #{e.message}")
    end
  end
end
