require 'mail'

# Description: Sublayer::Action responsible for sending an email notification to a specified recipient.
# This action integrates with a mail server to send emails with a given subject and body.
#
# It is initialized with a recipient_email, subject, and body.
# It returns a confirmation message upon successful email dispatch.
#
# Example usage: When you want to notify a user about the completion of an AI process or provide updates on AI-driven tasks.

class EmailNotificationAction < Sublayer::Actions::Base
  def initialize(recipient_email:, subject:, body:)
    @recipient_email = recipient_email
    @subject = subject
    @body = body
    @mail_options = {
      address:              'smtp.gmail.com',
      port:                 587,
      domain:               'your.domain.com',
      user_name:            ENV['SMTP_USERNAME'],
      password:             ENV['SMTP_PASSWORD'],
      authentication:       'plain',
      enable_starttls_auto: true
    }
  end

  def call
    begin
      send_email
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
      "Email sent successfully to #{@recipient_email}"
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def send_email
    Mail.defaults do
      delivery_method :smtp, @mail_options
    end

    Mail.deliver do
      to @recipient_email
      from ENV['SMTP_FROM_ADDRESS']
      subject @subject
      body @body
    end
  end
end
