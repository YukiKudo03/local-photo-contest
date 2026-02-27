# frozen_string_literal: true

module My
  class NotificationsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_notification, only: [ :show ]

    def index
      @notifications = current_user.notifications.recent.includes(:notifiable)
    end

    def show
      @notification.mark_as_read!
    end

    def mark_all_as_read
      Notification.mark_all_as_read!(current_user)
      redirect_to my_notifications_path, notice: t('flash.notifications.marked_all_read')
    end

    private

    def set_notification
      @notification = current_user.notifications.find(params[:id])
    end

    def notification_redirect_path(notification)
      case notification.notifiable_type
      when "Contest"
        contest_results_path(notification.notifiable)
      when "Entry"
        entry_path(notification.notifiable)
      else
        my_notifications_path
      end
    end
  end
end
