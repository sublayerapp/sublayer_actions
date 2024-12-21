require 'net/smtp'

# Description: Sublayer::Action responsible for sending emails using SMTP.
# This action allows for easy integration of email sending capabilities into Sublayer workflows.
#
# It is initialized with recipient, subject, body, and optional SMTP configuration.
# It returns a boolean indicating whether the email was sent successfully.
#
# Example usage: When you want to send email notifications or updates from AI-driven processes.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(recipient:, subject:, body:, from: ENV['SMTP_FROM_EMAIL'], smtp_server: ENV['SMTP_SERVER'], smtp_port: ENV['SMTP_PORT'], smtp_username: ENV['SMTP_USERNAME'], smtp_password: ENV['SMTP_PASSWORD'])
    @recipient = recipient
    @subject = subject
    @body = body
    @from = from
    @smtp_server = smtp_server
    @smtp_port = smtp_port.to_i
    @smtp_username = smtp_username
    @smtp_password = smtp_password
  end

  def call
    begin
      Net::SMTP.start(@smtp_server, @smtp_port, 'localhost', @smtp_username, @smtp_password, :login) do |smtp|
        smtp.send_message compose_message, @from, @recipient
      end
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient}")
      true
    rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      false
    end
  end

  private

  def compose_message
    message = <<~MESSAGE
      From: #{@from}
      To: #{@recipient}
      Subject: #{@subject}

      #{@body}
    MESSAGE
    message
  end
end
