require 'net/smtp'

# Description: Sublayer::Action responsible for sending email notifications. This action integrates with
# email service providers through SMTP, allowing notifications to be sent upon specific events or updates.
#
# It is initialized with SMTP settings, recipient email, subject, and body of the email.
# It confirms the email has been sent through logging.
#
# Example usage: When you need to alert team members about the completion of an AI-driven process or a status update.

class EmailNotificationAction < Sublayer::Actions::Base
  def initialize(smtp_settings:, recipient_email:, subject:, body:)
    @smtp_settings = smtp_settings
    @recipient_email = recipient_email
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
      To: #{@recipient_email}
      Subject: #{@subject}

      #{@body}
    MESSAGE_END

    Net::SMTP.start(@smtp_settings[:address], @smtp_settings[:port], @smtp_settings[:domain],
                    @smtp_settings[:user_name], @smtp_settings[:password], @smtp_settings[:authentication]) do |smtp|
      smtp.send_message message, @smtp_settings[:from], @recipient_email
    end

    Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
  end
end
