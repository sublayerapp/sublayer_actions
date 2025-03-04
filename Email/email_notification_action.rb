require 'net/smtp'

# Description: Sublayer::Action responsible for sending email notifications via SMTP.
# This action is useful for alerting users to important events or updates in AI-driven processes.
#
# It is initialized with smtp_settings, recipient, subject, and body.
# It returns a confirmation that the email was sent or raises an error if it failed.
#
# Example usage: When you want to notify a user of an important change or result from an AI process.

class EmailNotificationAction < Sublayer::Actions::Base
  def initialize(smtp_settings:, recipient:, subject:, body:)
    @smtp_settings = smtp_settings
    @recipient = recipient
    @subject = subject
    @body = body
  end

  def call
    send_email
  rescue StandardError => e
    error_message = "Error sending email: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def send_email
    message = <<~MESSAGE_END
      From: #{@smtp_settings[:from]}
      To: #{@recipient}
      Subject: #{@subject}

      #{@body}
    MESSAGE_END

    Net::SMTP.start(@smtp_settings[:address],
                    @smtp_settings[:port],
                    @smtp_settings[:domain],
                    @smtp_settings[:user_name],
                    @smtp_settings[:password],
                    @smtp_settings[:authentication]) do |smtp|
      smtp.send_message message, @smtp_settings[:from], @recipient
    end
    Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient}")
  rescue Net::SMTPFatalError, Net::SMTPSyntaxError => e
    error_message = "SMTP error: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end
end
