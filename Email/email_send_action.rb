require 'net/smtp'

# Description: Sublayer::Action responsible for sending emails.
# This action can be used for automated notifications, sending AI-generated reports,
# or communicating results from Sublayer workflows to stakeholders.
#
# It is initialized with the recipient's email, subject, body, and optional sender email and SMTP settings.
# It returns true if the email was sent successfully, false otherwise.
#
# Example usage: When you want to send an email notification or report from an AI process to stakeholders.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, from: nil, smtp_address: nil, smtp_port: nil, smtp_username: nil, smtp_password: nil)
    @to = to
    @subject = subject
    @body = body
    @from = from || ENV['DEFAULT_FROM_EMAIL']
    @smtp_address = smtp_address || ENV['SMTP_ADDRESS']
    @smtp_port = smtp_port || ENV['SMTP_PORT']
    @smtp_username = smtp_username || ENV['SMTP_USERNAME']
    @smtp_password = smtp_password || ENV['SMTP_PASSWORD']
  end

  def call
    begin
      message = <<MESSAGE_END
From: #{@from}
To: #{@to}
Subject: #{@subject}

#{@body}
MESSAGE_END

      Net::SMTP.start(@smtp_address, @smtp_port, 'localhost', @smtp_username, @smtp_password, :login) do |smtp|
        smtp.send_message message, @from, @to
      end

      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      true
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      false
    end
  end
end