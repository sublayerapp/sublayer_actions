require 'net/smtp'
require 'json'

# Description: Sublayer::Action responsible for sending an email notification via SMTP.
# Useful for alerting interested parties about actions taken by an AI agent.
#
# It is initialized with recipients, subject, body, and SMTP settings.
# Returns a success message upon completion.
#
# Example usage: When you need to notify team members about a completed AI task or an important event occurred within your application.

class EmailNotificationAction < Sublayer::Actions::Base
  def initialize(smtp_settings:, recipients:, subject:, body:)
    @smtp_settings = smtp_settings
    @recipients = recipients
    @subject = subject
    @body = body
  end

  def call
    send_email
  rescue Net::SMTPFatalError, Net::SMTPSyntaxError => e
    error_message = "SMTP error during email sending: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error sending email: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  else
    Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipients}")
  end

  private

  def send_email
    message = <<~MESSAGE_END
      From: Sublayer Notification <#{@smtp_settings[:from]}>
      To: #{@recipients.join(", ")}
      Subject: #{@subject}

      #{@body}
    MESSAGE_END

    Net::SMTP.start(@smtp_settings[:address], @smtp_settings[:port], @smtp_settings[:domain],
                    @smtp_settings[:user_name], @smtp_settings[:password], @smtp_settings[:authentication]) do |smtp|
      smtp.send_message message, @smtp_settings[:from], @recipients
    end
  end
end
