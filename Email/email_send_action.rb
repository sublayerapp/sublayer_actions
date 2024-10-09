require 'net/smtp'

# Description: Sublayer::Action responsible for sending emails using SMTP.
# This action can be used to automate email notifications or send AI-generated content via email.
#
# It is initialized with the recipient's email, subject, body, and optional SMTP settings.
# It returns true if the email was sent successfully, false otherwise.
#
# Example usage: When you want to send an email notification or AI-generated content from your Sublayer workflow.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, from: nil, smtp_server: nil, smtp_port: nil, smtp_username: nil, smtp_password: nil)
    @to = to
    @subject = subject
    @body = body
    @from = from || ENV['DEFAULT_FROM_EMAIL']
    @smtp_server = smtp_server || ENV['SMTP_SERVER']
    @smtp_port = smtp_port || ENV['SMTP_PORT']&.to_i || 587
    @smtp_username = smtp_username || ENV['SMTP_USERNAME']
    @smtp_password = smtp_password || ENV['SMTP_PASSWORD']
  end

  def call
    message = <<~MESSAGE
      From: #{@from}
      To: #{@to}
      Subject: #{@subject}

      #{@body}
    MESSAGE

    begin
      Net::SMTP.start(@smtp_server, @smtp_port, 'localhost', @smtp_username, @smtp_password, :login) do |smtp|
        smtp.send_message(message, @from, @to)
      end
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      true
    rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      false
    end
  end
end