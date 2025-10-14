require 'net/smtp'

# Description: Sublayer::Action responsible for sending email notifications with a customizable message and subject.
# Supports SMTP configuration for integration with various email providers.
#
# It is initialized with smtp_settings (including address, port, domain, username, password, and authentication),
# the recipient email address, subject, and message.
# It returns true if the email is sent successfully.
#
# Example usage: Send notifications for AI-driven events or alerts to specified email addresses.

class EmailNotificationAction < Sublayer::Actions::Base
  def initialize(smtp_settings:, to:, subject:, message:)
    @smtp_settings = smtp_settings
    @to = to
    @subject = subject
    @message = message
  end

  def call
    send_email_notification
  rescue StandardError => e
    error_message = "Error sending email notification: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def send_email_notification
    email_content = <<~MESSAGE_END
      From: #{@smtp_settings[:username]}
      To: #{@to}
      Subject: #{@subject}

      #{@message}
    MESSAGE_END

    Net::SMTP.start(@smtp_settings[:address], @smtp_settings[:port], @smtp_settings[:domain],
                    @smtp_settings[:username], @smtp_settings[:password], @smtp_settings[:authentication]) do |smtp|
      smtp.send_message email_content, @smtp_settings[:username], @to
    end

    Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
    true
  end
end
