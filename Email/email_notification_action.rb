require 'net/smtp'

# Description: Sublayer::Action responsible for sending an automated email notification
# through a designated email server. Useful for alerting users or teams about
# the completion of AI tasks, errors, or important updates.
#
# Initialized with email configurations such as smtp_address, smtp_port, domain,
# sender_email, recipient_email, subject, and body.
# Returns true if the email is sent successfully.
#
# Example usage: An AI task processor completing a job and notifying the team.

class EmailNotificationAction < Sublayer::Actions::Base
  def initialize(smtp_address:, smtp_port:, domain:, sender_email:, recipient_email:, subject:, body:)
    @smtp_address = smtp_address
    @smtp_port = smtp_port
    @domain = domain
    @sender_email = sender_email
    @recipient_email = recipient_email
    @subject = subject
    @body = body
  end

  def call
    send_email
  rescue StandardError => e
    error_message = "Error sending email notification: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def send_email
    message = <<~MESSAGE
      From: #{@sender_email}
      To: #{@recipient_email}
      Subject: #{@subject}

      #{@body}
    MESSAGE

    Net::SMTP.start(@smtp_address, @smtp_port, @domain) do |smtp|
      smtp.send_message message, @sender_email, @recipient_email
    end

    Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
    true
  end
end
