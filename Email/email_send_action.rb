require 'net/smtp'

# Description: Sublayer::Action responsible for sending emails via SMTP.
# It allows sending emails with customizable subjects, bodies, and recipients.
#
# Example usage: When you want to send automated emails based on AI-generated content,
# or for notifications and alerts in Sublayer-driven processes.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(smtp_server:, port:, domain:, username:, password:, from_address:, to_address:, subject:, body:)
    @smtp_server = smtp_server
    @port = port
    @domain = domain
    @username = username
    @password = password
    @from_address = from_address
    @to_address = to_address
    @subject = subject
    @body = body
  end

  def call
    begin
      smtp = Net::SMTP.new(@smtp_server, @port)
      smtp.enable_starttls
      smtp.start(@domain, @username, @password, :login) do
        smtp.send_message(build_email, @from_address, @to_address)
      end
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to_address} with subject: #{@subject}")
    rescue Net::SMTPFatalError, Net::SMTPSyntaxError => e
      error_message = "SMTP error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def build_email
    <<~EMAIL
      From: #{@from_address}
      To: #{@to_address}
      Subject: #{@subject}

      #{@body}
    EMAIL
  end
end
