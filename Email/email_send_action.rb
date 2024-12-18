require 'net/smtp'

# Description: Sublayer::Action responsible for sending emails using a specified SMTP server.
# This action allows for easy integration of email functionality into Sublayer workflows,
# enabling the sending of notifications, reports, or other AI-generated content via email.
#
# It is initialized with recipient email, subject, body, and optional SMTP server details.
# It returns a boolean indicating whether the email was sent successfully.
#
# Example usage: When you want to send an email with AI-generated content or notifications from your Sublayer workflow.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, from: ENV['DEFAULT_FROM_EMAIL'],
                 smtp_address: ENV['SMTP_ADDRESS'], smtp_port: ENV['SMTP_PORT'],
                 smtp_username: ENV['SMTP_USERNAME'], smtp_password: ENV['SMTP_PASSWORD'])
    @to = to
    @subject = subject
    @body = body
    @from = from
    @smtp_address = smtp_address
    @smtp_port = smtp_port.to_i
    @smtp_username = smtp_username
    @smtp_password = smtp_password
  end

  def call
    begin
      send_email
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      true
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def send_email
    message = <<~MESSAGE
      From: #{@from}
      To: #{@to}
      Subject: #{@subject}

      #{@body}
    MESSAGE

    Net::SMTP.start(@smtp_address, @smtp_port, 'localhost', @smtp_username, @smtp_password, :login) do |smtp|
      smtp.send_message message, @from, @to
    end
  end
end
