require 'net/smtp'
require 'erb'

# Description: Sublayer::Action responsible for sending formatted emails via SMTP.
# This action supports HTML content and can be configured to work with various email providers.
#
# It is initialized with SMTP details, sender and recipient information, subject, and body (supports HTML).
# It also includes error handling and logging features.
#
# Example usage: Automate sending notifications or updates based on AI-driven tasks.

class EmailSenderAction < Sublayer::Actions::Base
  def initialize(smtp_address:, smtp_port:, smtp_domain:, smtp_user_name:, smtp_password:, 
                 from:, to:, subject:, body:, content_type: 'text/html')
    @smtp_address = smtp_address
    @smtp_port = smtp_port
    @smtp_domain = smtp_domain
    @smtp_user_name = smtp_user_name
    @smtp_password = smtp_password
    @from = from
    @to = to
    @subject = subject
    @body = body
    @content_type = content_type
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
    message = <<~MESSAGE_END
      From: #{@from}
      To: #{@to}
      MIME-Version: 1.0
      Content-type: #{@content_type}
      Subject: #{@subject}

      #{@body}
    MESSAGE_END

    Net::SMTP.start(@smtp_address, @smtp_port, @smtp_domain, @smtp_user_name, @smtp_password, :login) do |smtp|
      smtp.send_message message, @from, @to
    end
  end
end