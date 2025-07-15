require 'net/smtp'

# Description: Sublayer::Action responsible for sending an email using SMTP settings.
# This can be used for sending notifications, reports, or alerts via email.
#
# It is initialized with SMTP settings, recipient email, subject, and message body.
# Returns true on success and raises an error on failure.
#
# Example usage: Sending a notification email when a particular event occurs in the workflow.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(smtp_server:, smtp_port:, domain:, username:, password:, to:, subject:, body:)
    @smtp_server = smtp_server
    @smtp_port = smtp_port
    @domain = domain
    @username = username
    @password = password
    @to = to
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
      From: #{@username}
      To: #{@to}
      Subject: #{@subject}

      #{@body}
    MESSAGE_END

    Net::SMTP.start(@smtp_server, @smtp_port, @domain, @username, @password, :plain) do |smtp|
      smtp.send_message message, @username, @to
    end

    Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
    true
  end
end
