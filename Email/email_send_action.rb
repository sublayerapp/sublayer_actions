require 'mail'

# Description: Sublayer::Action responsible for sending emails via SMTP.
# This action enables sending emails from AI workflows for notifications and updates.
#
# Requires: 'mail' gem
# $ gem install mail
# Or add `gem 'mail'` to your Gemfile
#
# It is initialized with recipient(s), subject, body, and optional from address and attachments.
# It returns true on successful email delivery.
#
# Configuration:
# Requires the following environment variables:
# - SMTP_ADDRESS: SMTP server address (e.g., 'smtp.gmail.com')
# - SMTP_PORT: SMTP port (e.g., 587)
# - SMTP_USERNAME: SMTP authentication username
# - SMTP_PASSWORD: SMTP authentication password
# - SMTP_DOMAIN: SMTP domain (e.g., 'yourdomain.com')
#
# Example usage: When you want to send email notifications or updates from an AI-driven process.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, from: nil, attachments: [])
    @to = Array(to)  # Convert single email to array
    @subject = subject
    @body = body
    @from = from || ENV['SMTP_USERNAME']
    @attachments = attachments
    
    configure_smtp
  end

  def call
    begin
      deliver_email
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to.join(', ')}")
      true
    rescue Mail::DeliveryError => e
      error_message = "Email delivery failed: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def configure_smtp
    Mail.defaults do
      delivery_method :smtp, {
        address: ENV['SMTP_ADDRESS'],
        port: ENV['SMTP_PORT'],
        domain: ENV['SMTP_DOMAIN'],
        user_name: ENV['SMTP_USERNAME'],
        password: ENV['SMTP_PASSWORD'],
        authentication: 'plain',
        enable_starttls_auto: true
      }
    end
  end

  def deliver_email
    Mail.new do
      from     @from
      to       @to
      subject  @subject
      body     @body

      @attachments.each do |attachment|
        add_file attachment
      end
    end.deliver!
  end
end