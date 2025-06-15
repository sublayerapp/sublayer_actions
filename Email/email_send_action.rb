require 'net/smtp'

# Description: Sublayer::Action responsible for sending an email through SMTP.
# This action allows systems to send notifications or reports to users via email.
#
# It is initialized with a recipient email, subject, and email body.
# It logs success or failure of sending the email.
#
# Example usage: When you want to send system alerts or user reports via email.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(smtp_settings:, recipient_email:, subject:, body:)
    @smtp_settings = smtp_settings
    @recipient_email = recipient_email
    @subject = subject
    @body = body
  end

  def call
    begin
      send_email
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def send_email
    message = <<~MESSAGE_END
      From: #{@smtp_settings[:from]}
      To: #{@recipient_email}
      Subject: #{@subject}

      #{@body}
    MESSAGE_END

    Net::SMTP.start(@smtp_settings[:address], @smtp_settings[:port], @smtp_settings[:domain],
                    @smtp_settings[:user_name], @smtp_settings[:password], @smtp_settings[:authentication]) do |smtp|
      smtp.send_message message, @smtp_settings[:from], @recipient_email
    end
  end
end
