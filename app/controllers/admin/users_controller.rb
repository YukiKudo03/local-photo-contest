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
