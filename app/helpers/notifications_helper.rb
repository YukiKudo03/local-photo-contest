# frozen_string_literal: true

module NotificationsHelper
  def notification_link_path(notification)
    case notification.notifiable_type
    when "Contest"
      contest_results_path(notification.notifiable)
    when "Entry"
      entry_path(notification.notifiable)
    end
  end
end
