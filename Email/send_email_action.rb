# Description: Sublayer::Action responsible for sending emails.
# This action allows Sublayer agents and generators to send emails.
#
# It is initialized with recipient_email, subject, and body.
# It returns "Email sent successfully" if sent, raises an error otherwise.
#
# Example usage: When you want to send email notifications or updates from an AI process.

require 'mail'

class SendEmailAction < Sublayer::Actions::Base
  def initialize(recipient_email:, subject:, body:)
    @recipient_email = recipient_email
    @subject = subject
    @body = body
  end

  def call
    begin
      mail = Mail.new do
        from    ENV['EMAIL_FROM'] || 'sublayer@example.com'
        to      @recipient_email
        subject @subject
        body    @body
      end

      mail.delivery_method :smtp, {
        address:              ENV['EMAIL_SMTP_ADDRESS'] || 'smtp.example.com',
        port:                 ENV['EMAIL_SMTP_PORT'] || 587,
        domain:               ENV['EMAIL_SMTP_DOMAIN'] || 'example.com',
        user_name:            ENV['EMAIL_SMTP_USERNAME'],
        password:             ENV['EMAIL_SMTP_PASSWORD'],
        authentication:       ENV['EMAIL_SMTP_AUTH'] || 'plain',
        enable_starttls_auto: ENV['EMAIL_SMTP_STARTTLS'] == 'true'
      }

      mail.deliver

      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
      "Email sent successfully"
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end
end