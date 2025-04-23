require 'net/smtp'

# Description: Sublayer::Action responsible for sending an email using SMTP.
# This action allows sending emails through an SMTP server. It supports basic configurations such as
# SMTP server address, port, domain, user credentials, and email content details.
#
# Example usage: When you need to send notifications, alerts, or any information via email in your
# Sublayer workflows.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(smtp_address:, smtp_port:, domain:, username:, password:, from:, to:, subject:, body:)
    @smtp_address = smtp_address
    @smtp_port = smtp_port
    @domain = domain
    @username = username
    @password = password
    @from = from
    @to = to
    @subject = subject
    @body = body
  end

  def call
    send_email
  rescue Net::SMTPFatalError => e
    error_message = "SMTP fatal error: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue Net::SMTPAuthenticationError => e
    error_message = "SMTP authentication error: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error sending email: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def send_email
    message = <<~MESSAGE_END
      From: #{@from}
      To: #{@to}
      Subject: #{@subject}

      #{@body}
    MESSAGE_END

    Net::SMTP.start(@smtp_address, @smtp_port, @domain, @username, @password, :login) do |smtp|
      smtp.send_message message, @from, @to
    end

    Sublayer.configuration.logger.log(:info, "Email sent successfully from #{@from} to #{@to}")
  end
end
