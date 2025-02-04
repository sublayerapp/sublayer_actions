require 'net/smtp'

# Description: Sublayer::Action responsible for sending an email through SMTP.
# Useful for sending notifications or reports from Sublayer workflows.
#
# It is initialized with to, subject, and message parameters.
# It returns true if the email was sent successfully.
#
# Example usage: Sending a report or notification to a team member via email.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(to:, subject:, message:, smtp_server: 'localhost', smtp_port: 25)
    @to = to
    @subject = subject
    @message = message
    @smtp_server = smtp_server
    @smtp_port = smtp_port
  end

  def call
    email = build_email
    send_email(email)
  end

  private

  def build_email
    <<~EMAIL
      From: Sublayer Notifications <no-reply@sublayerapp.com>
      To: #{@to}
      Subject: #{@subject}

      #{@message}
    EMAIL
  end

  def send_email(email)
    Net::SMTP.start(@smtp_server, @smtp_port) do |smtp|
      smtp.send_message email, 'no-reply@sublayerapp.com', @to
    end
    Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
    true
  rescue Net::SMTPFatalError, Net::SMTPSyntaxError => e
    error_message = "Failed to send email: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end
end