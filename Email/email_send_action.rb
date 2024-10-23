require 'mail'

# Description: Sublayer::Action responsible for sending emails using a specified email service.
# This action enables AI-driven communication and automation via email.
#
# It is initialized with the sender's email address, recipient's email address, subject, and body.
# It returns true if the email was sent successfully, otherwise, it raises an error.
#
# Example usage: An AI customer support agent that drafts and sends personalized email responses to customer queries.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(sender_email:, recipient_email:, subject:, body:)
    @sender_email = sender_email
    @recipient_email = recipient_email
    @subject = subject
    @body = body

    # Use environment variables for SMTP settings
    Mail.defaults do
      delivery_method :smtp, address: ENV['SMTP_ADDRESS'], port: ENV['SMTP_PORT'],
                       user_name: ENV['SMTP_USERNAME'], password: ENV['SMTP_PASSWORD'],
                       authentication: ENV['SMTP_AUTHENTICATION'] || :plain, enable_starttls_auto: true
    end
  end

  def call
    begin
      mail = Mail.new do
        from    @sender_email
        to      @recipient_email
        subject @subject
        body    @body
      end

      mail.deliver!

      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
      true
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end
end