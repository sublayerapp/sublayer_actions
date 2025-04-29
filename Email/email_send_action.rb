# Description: Sublayer::Action responsible for sending emails via a specified email provider.
# Supports SMTP for now, but other providers like SendGrid and Mailgun can be easily added.
#
# It accepts parameters like sender, recipient, subject, body, and attachments.
# It returns the message ID if successful, raises an exception otherwise.
#
# Example usage: Sending notifications, reports, or other email communications from a Sublayer workflow.

require 'mail'

class EmailSendAction < Sublayer::Actions::Base
  def initialize(sender:, recipient:, subject:, body:, attachments: [], smtp_settings: {})
    @sender = sender
    @recipient = recipient
    @subject = subject
    @body = body
    @attachments = attachments
    @smtp_settings = smtp_settings.reverse_merge({
        address:              ENV['SMTP_ADDRESS'],
        port:                 ENV['SMTP_PORT'].to_i || 587,
        domain:               ENV['SMTP_DOMAIN'],
        user_name:            ENV['SMTP_USERNAME'],
        password:             ENV['SMTP_PASSWORD'],
        authentication:       ENV['SMTP_AUTHENTICATION'] || :plain,
        enable_starttls_auto: ENV['SMTP_ENABLE_STARTTLS_AUTO'] == 'true' || true
    })
  end

  def call
    begin
      mail = Mail.new do
        from    @sender
        to      @recipient
        subject @subject
        body    @body
      end

      @attachments.each do |attachment|
        mail.add_file(attachment)
      end

      mail.delivery_method :smtp, @smtp_settings

      message_id = mail.deliver!
      Sublayer.configuration.logger.log(:info, "Email sent successfully. Message ID: #{message_id}")
      return message_id
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end