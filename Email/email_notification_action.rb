require 'net/smtp'

# Description: Sublayer::Action responsible for sending an email notification through a configurable SMTP server.
# This action is useful for alerting users or administrators about important updates or results of AI-driven tasks.
#
# It is initialized with smtp_settings, to, subject, and body.
# It returns true if the email was sent successfully, otherwise raises an error.
#
# Example usage:
# When you want to notify users about the completion of an AI-driven task.

class EmailNotificationAction < Sublayer::Actions::Base
  def initialize(smtp_settings:, to:, subject:, body:)
    @smtp_settings = smtp_settings
    @to = to
    @subject = subject
    @body = body
  end

  def call
    message = build_email_message

    Net::SMTP.start(@smtp_settings[:address], @smtp_settings[:port], @smtp_settings[:domain],
                    @smtp_settings[:user_name], @smtp_settings[:password], @smtp_settings[:authentication]) do |smtp|
      smtp.send_message message, @smtp_settings[:user_name], @to
    end

    Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
    true
  rescue Net::SMTPFatalError, Net::SMTPServerBusy, IOError => e
    error_message = "Error sending email: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def build_email_message
    <<~MESSAGE_END
      From: #{@smtp_settings[:user_name]}
      To: #{@to}
      Subject: #{@subject}

      #{@body}
    MESSAGE_END
  end
end