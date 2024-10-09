require 'net/smtp'

# Description: Sublayer::Action responsible for sending emails using SMTP.
# This action allows easy integration of email notifications or updates into Sublayer workflows,
# expanding communication capabilities beyond chat platforms.
#
# It is initialized with recipient email, subject, body, and optional SMTP settings.
# It returns true if the email was sent successfully.
#
# Example usage: When you want to send email notifications or updates from an AI process.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, from: ENV['EMAIL_FROM'], smtp_address: ENV['SMTP_ADDRESS'], smtp_port: ENV['SMTP_PORT'], smtp_username: ENV['SMTP_USERNAME'], smtp_password: ENV['SMTP_PASSWORD'])
    @to = to
    @subject = subject
    @body = body
    @from = from
    @smtp_address = smtp_address
    @smtp_port = smtp_port
    @smtp_username = smtp_username
    @smtp_password = smtp_password
  end

  def call
    message = <<~MESSAGE_END
      From: #{@from}
      To: #{@to}
      Subject: #{@subject}

      #{@body}
    MESSAGE_END

    begin
      Net::SMTP.start(@smtp_address, @smtp_port, 'localhost', @smtp_username, @smtp_password, :login) do |smtp|
        smtp.send_message message, @from, @to
      end
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      true
    rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end