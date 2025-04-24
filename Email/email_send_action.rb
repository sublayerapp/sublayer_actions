require 'net/smtp'

# Description: Sublayer::Action responsible for sending an email using SMTP.
# This action allows for easy integration of email notifications or reports
# into Sublayer workflows, which can be particularly useful for sending
# AI-generated insights or automated updates.
#
# It is initialized with recipient email, subject, body, and optional sender email and SMTP settings.
# It returns true if the email was sent successfully, false otherwise.
#
# Example usage: When you want to send an email with AI-generated content or notifications from your Sublayer workflow.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, from: nil, smtp_address: nil, smtp_port: nil, smtp_username: nil, smtp_password: nil)
    @to = to
    @subject = subject
    @body = body
    @from = from || ENV['DEFAULT_FROM_EMAIL']
    @smtp_address = smtp_address || ENV['SMTP_ADDRESS']
    @smtp_port = smtp_port || ENV['SMTP_PORT']&.to_i || 587
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
      false
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
      smtp.send_message(message, @from, @to)
    end
  end
end