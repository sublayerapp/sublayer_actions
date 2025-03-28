require 'mail'

# Description: Sublayer::Action responsible for sending emails via SMTP or email service providers.
# This action supports sending HTML or plain text emails with optional attachments.
#
# Requires: 'mail' gem
# $ gem install mail
# Or add `gem 'mail'` to your Gemfile
#
# It is initialized with required email parameters and optional configurations.
# Returns a Mail::Message object of the sent email for confirmation.
#
# Example usage: When you want to send AI-generated reports, notifications, or updates to stakeholders via email.
# Can be used to distribute LLM-generated content, analysis results, or automated reports.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, from: nil, html_body: nil, attachments: [], smtp_settings: {})
    @to = to
    @subject = subject
    @body = body
    @from = from || ENV['EMAIL_DEFAULT_FROM']
    @html_body = html_body
    @attachments = attachments
    @smtp_settings = default_smtp_settings.merge(smtp_settings)
    
    configure_mail_settings
  end

  def call
    begin
      email = create_email
      email.deliver!
      
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      email
    rescue Mail::DeliveryError => e
      error_message = "Failed to deliver email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def default_smtp_settings
    {
      address: ENV['SMTP_ADDRESS'] || 'smtp.sendgrid.net',
      port: ENV['SMTP_PORT'] || 587,
      domain: ENV['SMTP_DOMAIN'],
      user_name: ENV['SMTP_USERNAME'],
      password: ENV['SMTP_PASSWORD'],
      authentication: :plain,
      enable_starttls_auto: true
    }
  end

  def configure_mail_settings
    Mail.defaults do
      delivery_method :smtp, @smtp_settings
    end
  end

  def create_email
    Mail.new do |m|
      m.to = @to
      m.from = @from
      m.subject = @subject

      if @html_body
        m.html_part do
          content_type 'text/html; charset=UTF-8'
          body @html_body
        end

        m.text_part do
          body @body
        end
      else
        m.body = @body
      end

      @attachments.each do |attachment|
        m.add_file(attachment)
      end
    end
  end
end