require 'net/smtp'

# Description: Sublayer::Action responsible for sending emails using SMTP.
# This action is intended to be used for sending notifications, reports, or alerts
# stemming from other Sublayer processes.
#
# It is initialized with SMTP settings, recipient email, subject, and message body.
# It returns true if the email was sent successfully.
#
# Example usage: Sending a report or alert notification via email.

class EmailSendingAction < Sublayer::Actions::Base
  def initialize(smtp_settings:, recipient_email:, subject:, message_body:)
    @smtp_settings = smtp_settings
    @recipient_email = recipient_email
    @subject = subject
    @message_body = message_body
  end

  def call
    send_email
    Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
    true
  rescue StandardError => e
    Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
    raise e
  end

  private

  def send_email
    message = <<~MESSAGE_END
      From: #{@smtp_settings[:from_name]} <#{@smtp_settings[:from_email]}>
      To: <#{@recipient_email}>
      Subject: #{@subject}

      #{@message_body}
    MESSAGE_END

    Net::SMTP.start(@smtp_settings[:address], @smtp_settings[:port],
                    @smtp_settings[:domain], @smtp_settings[:user_name],
                    @smtp_settings[:password], @smtp_settings[:authentication]) do |smtp|
      smtp.send_message message, @smtp_settings[:from_email], @recipient_email
    end
  end
end