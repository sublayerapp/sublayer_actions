require 'mail'

# Description: Sublayer::Action responsible for sending emails using the 'mail' gem.
# This action provides a generic way to send emails, which can be useful for notifications,
# reports, or sending AI-generated content via email.
#
# Requires: 'mail' gem
# $ gem install mail
# Or add `gem 'mail'` to your Gemfile
#
# It is initialized with recipient email, subject, body, and optional sender email and attachments.
# It returns a boolean indicating whether the email was sent successfully.
#
# Example usage: When you want to send an email with AI-generated content or notifications from your Sublayer workflow.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, from: nil, attachments: [])
    @to = to
    @subject = subject
    @body = body
    @from = from || ENV['DEFAULT_FROM_EMAIL']
    @attachments = attachments
    
    Mail.defaults do
      delivery_method :smtp, {
        address: ENV['SMTP_ADDRESS'],
        port: ENV['SMTP_PORT'],
        user_name: ENV['SMTP_USERNAME'],
        password: ENV['SMTP_PASSWORD'],
        authentication: 'plain',
        enable_starttls_auto: true
      }
    end
  end

  def call
    begin
      mail = Mail.new do
        from     @from
        to       @to
        subject  @subject
        body     @body
      end

      @attachments.each do |attachment|
        mail.add_file(attachment)
      end

      mail.deliver!
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      true
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      false
    end
  end
end
