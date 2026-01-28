# frozen_string_literal: true

module Admin
  class AuditLogsController < BaseController
    def index
      @audit_logs = AuditLog.includes(:user).order(created_at: :desc)
      @audit_logs = @audit_logs.where(action: params[:action_type]) if params[:action_type].present?
      @audit_logs = @audit_logs.where(user_id: params[:user_id]) if params[:user_id].present?
      @audit_logs = @audit_logs.where("created_at >= ?", params[:from].to_date) if params[:from].present?
      @audit_logs = @audit_logs.where("created_at <= ?", params[:to].to_date.end_of_day) if params[:to].present?
      @audit_logs = @audit_logs.page(params[:page]).per(50)
    end

    def show
      @audit_log = AuditLog.find(params[:id])
    end
  end
end
