require 'net/smtp'

# Description: Sublayer::Action responsible for sending automated emails as part of a workflow.
# This action integrates with SMTP servers and can be configured to work with systems like Gmail or Outlook.
#
# It is initialized with recipients, subject, body, and SMTP server details.
# It returns a success message upon sending the email or raises an error if it fails.
#
# Example usage: When you want to send alerts or summaries of AI-driven actions via email.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(smtp_server:, port:, domain:, user_name:, password:, to:, from:, subject:, body:)
    @smtp_server = smtp_server
    @port = port
    @domain = domain
    @user_name = user_name
    @password = password
    @to = to
    @from = from
    @subject = subject
    @body = body
  end

  def call
    begin
      send_email
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def send_email
    msg = <<~END_OF_MESSAGE
      From: #{@from}
      To: #{@to}
      Subject: #{@subject}

      #{@body}
    END_OF_MESSAGE

    Net::SMTP.start(@smtp_server, @port, @domain, @user_name, @password, :login) do |smtp|
      smtp.send_message msg, @from, @to
    end
  end
end
