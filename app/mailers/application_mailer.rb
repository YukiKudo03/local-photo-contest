class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "noreply@local-photo-contest.example.com")
  layout "mailer"

  private

  def unsubscribe_url_for(user)
    email_preference_url(token: user.ensure_unsubscribe_token!)
  end
end
