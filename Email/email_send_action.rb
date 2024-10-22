require 'net/imap'

# Description: Sublayer::Action for sending emails using SMTP.
# This action allows Sublayer agents to send emails within workflows.
#
# It is initialized with the sender's email, recipient's email, email subject, and body.
# It returns true if the email was sent successfully, otherwise raises an error.
#
# Example usage: When you want to send a notification or alert from an AI process via email.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(sender_email:, recipient_email:, subject:, body:)
    @sender_email = sender_email
    @recipient_email = recipient_email
    @subject = subject
    @body = body
  end

  def call
    begin
      send_email
      Sublayer.configuration.logger.log(:info, "Email sent successfully from \#{@sender_email} to \#{@recipient_email}")
      true
    rescue StandardError => e
      error_message = "Error sending email: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def send_email
    mail = Mail.new do
      from    @sender_email
      to      @recipient_email
      subject @subject
      body    @body
    end

    mail.delivery_method :sendmail
    mail.deliver
  end
end