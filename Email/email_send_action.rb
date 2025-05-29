require 'mail'

# Description: Sublayer::Action responsible for sending emails using SMTP or email service providers.
# This action supports sending emails with HTML content, plain text fallback, and attachments.
#
# Requires: 'mail' gem
# $ gem install mail
# Or add `gem 'mail'` to your Gemfile
#
# It is initialized with essential email parameters and optional configuration settings.
# It returns a hash containing the message_id and delivery status.
#
# Example usage: When you want to send AI-generated content, reports, or notifications via email.
# Can be used to deliver formatted content from LLM outputs to stakeholders.

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
      email = build_email
      email.deliver!
      
      result = {
        message_id: email.message_id,
        status: 'delivered'
      }
      
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      result
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

  def default_smtp_settings
    {
      address: ENV['SMTP_ADDRESS'] || 'smtp.gmail.com',
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

  def build_email
    Mail.new do |m|
      m.to = @to
      m.from = @from
      m.subject = @subject
      
      if @html_body
        m.html_part = Mail::Part.new do |p|
          p.content_type 'text/html; charset=UTF-8'
          p.body = @html_body
        end
        
        m.text_part = Mail::Part.new do |p|
          p.content_type 'text/plain; charset=UTF-8'
          p.body = @body
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