# frozen_string_literal: true

module Organizers
  class RegistrationsController < Devise::RegistrationsController
    protected

    def after_inactive_sign_up_path_for(resource)
      flash[:notice] = "確認メールを送信しました。メール内のリンクをクリックしてアカウントを有効化してください。"
      root_path
    end
  end
end
