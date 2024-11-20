require 'net/smtp'

# Description: Sublayer::Action responsible for sending an email using a specified SMTP server.
# This action allows for easy integration of email sending capabilities into Sublayer workflows,
# enabling notifications, reports, or other AI-generated content to be sent via email.
#
# It is initialized with recipient email, subject, body, and optional SMTP server settings.
# On successful execution, it sends the email and returns the result of the SMTP transaction.
#
# Example usage: When you want to send AI-generated reports or notifications via email.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, from: ENV['DEFAULT_FROM_EMAIL'], smtp_server: ENV['SMTP_SERVER'], smtp_port: ENV['SMTP_PORT'], smtp_username: ENV['SMTP_USERNAME'], smtp_password: ENV['SMTP_PASSWORD'])
    @to = to
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
      message = compose_message
      send_email(message)
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      true
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def compose_message
    message = <<~MESSAGE
      From: #{@from}
      To: #{@to}
      Subject: #{@subject}

      #{@body}
    MESSAGE
    message
  end

  def send_email(message)
    Net::SMTP.start(@smtp_server, @smtp_port, 'localhost', @smtp_username, @smtp_password, :login) do |smtp|
      smtp.send_message message, @from, @to
    end
  end
end