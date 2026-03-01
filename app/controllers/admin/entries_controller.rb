# frozen_string_literal: true

module Admin
  class EntriesController < BaseController
    MAX_BULK_SIZE = 100

    def index
      @entries = Entry.includes(:user, :contest, :moderation_result)
                      .needs_moderation_review
                      .order(created_at: :desc)
                      .page(params[:page]).per(20)
    end

    def bulk_approve
      entry_ids = Array(params[:entry_ids]).first(MAX_BULK_SIZE)
      if entry_ids.empty?
        return redirect_to admin_entries_path, alert: t("flash.admin.entries.no_entries_selected")
      end

      entries = Entry.where(id: entry_ids)
      count = 0
      entries.find_each do |entry|
        entry.moderation_approved!
        AuditLog.log(action: "moderation_approve", user: current_user, target: entry, details: { bulk: true }, ip_address: request.remote_ip)
        count += 1
      end

      redirect_to admin_entries_path, notice: t("flash.admin.entries.bulk_approved", count: count)
    end

    def bulk_reject
      entry_ids = Array(params[:entry_ids]).first(MAX_BULK_SIZE)
      if entry_ids.empty?
        return redirect_to admin_entries_path, alert: t("flash.admin.entries.no_entries_selected")
      end

      entries = Entry.where(id: entry_ids)
      count = 0
      entries.find_each do |entry|
        entry.moderation_hidden!
        AuditLog.log(action: "moderation_reject", user: current_user, target: entry, details: { bulk: true }, ip_address: request.remote_ip)
        count += 1
      end

      redirect_to admin_entries_path, notice: t("flash.admin.entries.bulk_rejected", count: count)
    end
  end
end
