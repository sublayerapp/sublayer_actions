require 'net/smtp'

# Description: Sublayer::Action responsible for sending emails using SMTP.
# This action allows for easy integration of email sending capabilities into Sublayer workflows,
# which can be useful for automated notifications, reports, or follow-ups based on AI-generated content.
#
# It is initialized with recipient email, subject, body, and optional sender email and SMTP settings.
# It returns true if the email was sent successfully.
#
# Example usage: When you want to send an email with AI-generated content or as part of an automated workflow.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, from: ENV['DEFAULT_FROM_EMAIL'],
                 smtp_address: ENV['SMTP_ADDRESS'],
                 smtp_port: ENV['SMTP_PORT'],
                 smtp_domain: ENV['SMTP_DOMAIN'],
                 smtp_username: ENV['SMTP_USERNAME'],
                 smtp_password: ENV['SMTP_PASSWORD'])
    @to = to
    @subject = subject
    @body = body
    @from = from
    @smtp_address = smtp_address
    @smtp_port = smtp_port
    @smtp_domain = smtp_domain
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

    Net::SMTP.start(@smtp_address, @smtp_port, @smtp_domain, @smtp_username, @smtp_password, :login) do |smtp|
      smtp.send_message message, @from, @to
    end
  end
end
