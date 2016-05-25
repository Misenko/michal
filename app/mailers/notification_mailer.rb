class NotificationMailer < ApplicationMailer
  def statistics_ready_email(email, url)
    @email = email
    @url = url

    mail(subject: 'Your statistic is ready!', to: @email)
  end
end
