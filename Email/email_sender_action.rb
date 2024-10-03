require 'net/smtp'
require 'logger'

# Description: Sublayer::Action responsible for sending emails using a specified SMTP server.
# This action can be used for sending notifications, reports, or AI-generated content to stakeholders or customers.
#
# It is initialized with SMTP server details and email content, and returns a boolean indicating success or failure.
#
# Example usage: When you want to send an email notification after an AI has generated a report or completed a task.

class EmailSenderAction < Sublayer::Actions::Base
  def initialize(smtp_address:, smtp_port:, smtp_username:, smtp_password:, from:, to:, subject:, body:)
    @smtp_address = smtp_address
    @smtp_port = smtp_port
    @smtp_username = smtp_username
    @smtp_password = smtp_password
    @from = from
    @to = to
    @subject = subject
    @body = body
    @logger = Logger.new(STDOUT)
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
      @logger.info("Email sent successfully to #{@to}")
      true
    rescue Net::SMTPAuthenticationError
      @logger.error("SMTP authentication failed")
      false
    rescue Net::SMTPServerBusy
      @logger.error("SMTP server is busy")
      false
    rescue Net::SMTPSyntaxError
      @logger.error("SMTP syntax error")
      false
    rescue Net::SMTPFatalError
      @logger.error("SMTP fatal error")
      false
    rescue StandardError => e
      @logger.error("An unexpected error occurred: #{e.message}")
      false
    end
  end
end