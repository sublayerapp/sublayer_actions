require 'net/smtp'

# Description: Sublayer::Action responsible for sending emails using a specified SMTP server.
# This action allows for automated email communication based on AI-generated content or analysis results.
#
# It is initialized with sender email, recipient email, subject, body, and SMTP server details.
# It returns a boolean indicating whether the email was sent successfully.
#
# Example usage: When you want to send an email notification or report based on AI-generated insights or automated processes.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(from:, to:, subject:, body:, smtp_server:, smtp_port:, smtp_username:, smtp_password:)
    @from = from
    @to = to
    @subject = subject
    @body = body
    @smtp_server = smtp_server
    @smtp_port = smtp_port
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
      false
    end
  end

  private

  def compose_message
    <<~MESSAGE
      From: #{@from}
      To: #{@to}
      Subject: #{@subject}

      #{@body}
    MESSAGE
  end

  def send_email(message)
    Net::SMTP.start(@smtp_server, @smtp_port, 'localhost', @smtp_username, @smtp_password, :login) do |smtp|
      smtp.send_message(message, @from, @to)
    end
  end
end
