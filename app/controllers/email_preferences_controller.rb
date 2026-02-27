# frozen_string_literal: true

class EmailPreferencesController < ApplicationController
  before_action :set_user_by_token

  def show
  end

  def update
    if @user.update(email_preferences_params)
      redirect_to email_preference_path(token: @user.unsubscribe_token),
                  notice: t('flash.email_preferences.updated')
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_user_by_token
    @user = User.find_by(unsubscribe_token: params[:token])
    redirect_to root_path, alert: t('flash.email_preferences.invalid_link') unless @user
  end

  def email_preferences_params
    params.require(:user).permit(
      :email_on_entry_submitted, :email_on_comment, :email_on_vote,
      :email_on_results, :email_digest, :email_on_judging
    )
  end
end
