require 'net/smtp'

# Description: Sublayer::Action responsible for sending an email using an SMTP server.
# This action is useful for sending notifications or routine communications via email.
#
# It is initialized with SMTP server settings, recipient email, subject, and message content.
# It returns a status message indicating success or failure of the email delivery.
#
# Example usage: When you want to send an email notification from an AI-driven process.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(smtp_settings:, recipient_email:, subject:, message:, **kwargs)
    super(**kwargs)
    @smtp_settings = smtp_settings
    @recipient_email = recipient_email
    @subject = subject
    @message = message
  end

  def call
    send_email
  rescue StandardError => e
    error_message = "Error sending email: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def send_email
    msg = <<~END_OF_MESSAGE
      From: #{@smtp_settings[:from_email]}
      To: #{@recipient_email}
      Subject: #{@subject}

      #{@message}
    END_OF_MESSAGE

    Net::SMTP.start(@smtp_settings[:address], @smtp_settings[:port], 
                    @smtp_settings[:domain], @smtp_settings[:user_name],
                    @smtp_settings[:password], @smtp_settings[:authentication]) do |smtp|
      smtp.send_message msg, @smtp_settings[:from_email], @recipient_email
    end

    Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
    "Email sent successfully"
  end
end