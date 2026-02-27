# frozen_string_literal: true

module My
  class ProfilesController < ApplicationController
    before_action :authenticate_user!

    def show
      @user = current_user
    end

    def edit
      @user = current_user
    end

    def update
      @user = current_user

      if @user.update(profile_params)
        redirect_to my_profile_path, notice: t('flash.profiles.updated')
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def profile_params
      params.require(:user).permit(:name, :bio, :avatar)
    end
  end
end
