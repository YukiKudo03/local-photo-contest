# frozen_string_literal: true

module Admin
  class UsersController < BaseController
    before_action :set_user, only: [ :show, :edit, :update, :destroy, :suspend, :unsuspend, :change_role ]

    def index
      @users = User.order(created_at: :desc)
      @users = @users.where("email LIKE ? OR name LIKE ?", "%#{params[:q]}%", "%#{params[:q]}%") if params[:q].present?
      @users = @users.where(role: params[:role]) if params[:role].present?
      @users = @users.page(params[:page]).per(20)
    end

    def show
      @contests = @user.contests.includes(:entries).order(created_at: :desc).limit(10)
      @entries = @user.entries.includes(:contest).order(created_at: :desc).limit(10)
    end

    def edit
    end

    def update
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: t('flash.admin.users.updated')
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @user.destroy
      redirect_to admin_users_path, notice: t('flash.admin.users.destroyed')
    end

    def suspend
      @user.update!(locked_at: Time.current)
      redirect_to admin_user_path(@user), notice: t('flash.admin.users.suspended')
    end

    def unsuspend
      @user.update!(locked_at: nil, failed_attempts: 0)
      redirect_to admin_user_path(@user), notice: t('flash.admin.users.unsuspended')
    end

    def change_role
      new_role = params[:role]
      if User.roles.keys.include?(new_role)
        @user.update!(role: new_role)
        redirect_to admin_user_path(@user), notice: t('flash.admin.users.role_changed', role: new_role)
      else
        redirect_to admin_user_path(@user), alert: t('flash.admin.users.invalid_role')
      end
    end

    MAX_BULK_SIZE = 100

    def bulk_suspend
      user_ids = Array(params[:user_ids]).first(MAX_BULK_SIZE)
      if user_ids.empty?
        return redirect_to admin_users_path, alert: t("flash.admin.users.no_users_selected")
      end

      users = User.where(id: user_ids).where.not(role: :admin).where(locked_at: nil)
      count = 0
      users.find_each do |user|
        user.update!(locked_at: Time.current)
        AuditLog.log(action: "account_suspend", user: current_user, target: user, details: { bulk: true }, ip_address: request.remote_ip)
        count += 1
      end

      redirect_to admin_users_path, notice: t("flash.admin.users.bulk_suspended", count: count)
    end

    def bulk_unsuspend
      user_ids = Array(params[:user_ids]).first(MAX_BULK_SIZE)
      if user_ids.empty?
        return redirect_to admin_users_path, alert: t("flash.admin.users.no_users_selected")
      end

      users = User.where(id: user_ids).where.not(locked_at: nil)
      count = 0
      users.find_each do |user|
        user.update!(locked_at: nil, failed_attempts: 0)
        AuditLog.log(action: "account_unsuspend", user: current_user, target: user, details: { bulk: true }, ip_address: request.remote_ip)
        count += 1
      end

      redirect_to admin_users_path, notice: t("flash.admin.users.bulk_unsuspended", count: count)
    end

    def bulk_change_role
      user_ids = Array(params[:user_ids]).first(MAX_BULK_SIZE)
      new_role = params[:role]

      unless User.roles.keys.include?(new_role)
        return redirect_to admin_users_path, alert: t("flash.admin.users.invalid_role")
      end

      if user_ids.empty?
        return redirect_to admin_users_path, alert: t("flash.admin.users.no_users_selected")
      end

      users = User.where(id: user_ids)
      count = 0
      users.find_each do |user|
        old_role = user.role
        next if old_role == new_role
        user.update!(role: new_role)
        AuditLog.log(action: "role_change", user: current_user, target: user, details: { old_role: old_role, new_role: new_role, bulk: true }, ip_address: request.remote_ip)
        count += 1
      end

      redirect_to admin_users_path, notice: t("flash.admin.users.bulk_role_changed", count: count, role: new_role)
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      # Note: :role is intentionally excluded - use change_role action instead
      params.require(:user).permit(:name, :bio)
    end
  end
end
