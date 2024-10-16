require 'net/smtp'

# Description: Sublayer::Action responsible for sending an email using SMTP.
# This action allows for easy integration of email sending capabilities into Sublayer workflows,
# which can be useful for sending notifications, reports, or other AI-generated content via email.
#
# It is initialized with sender email, recipient email, subject, body, and optional SMTP settings.
# It returns a boolean indicating whether the email was sent successfully.
#
# Example usage: When you want to send an email with AI-generated content or notifications from your Sublayer workflow.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(from:, to:, subject:, body:, smtp_address: 'smtp.gmail.com', smtp_port: 587, smtp_username: nil, smtp_password: nil)
    @from = from
    @to = to
    @subject = subject
    @body = body
    @smtp_address = smtp_address
    @smtp_port = smtp_port
    @smtp_username = smtp_username || ENV['SMTP_USERNAME']
    @smtp_password = smtp_password || ENV['SMTP_PASSWORD']
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
    Net::SMTP.start(@smtp_address, @smtp_port, 'localhost', @smtp_username, @smtp_password, :login) do |smtp|
      smtp.send_message message, @from, @to
    end
  end
end
