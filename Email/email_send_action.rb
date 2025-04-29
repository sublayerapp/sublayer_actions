require 'mail'

# Description: Sublayer::Action responsible for sending emails programmatically.
# This action allows for easy integration of email notifications or updates into AI-driven workflows.
#
# Requires: 'mail' gem
# $ gem install mail
# Or add `gem 'mail'` to your Gemfile
#
# It is initialized with recipient email, subject, and body. Optionally, you can provide sender email and SMTP settings.
# It returns a boolean indicating whether the email was sent successfully.
#
# Example usage: When you want to send email notifications or updates from an AI-driven process.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, from: nil, smtp_settings: {})
    @to = to
    @subject = subject
    @body = body
    @from = from || ENV['DEFAULT_FROM_EMAIL']
    @smtp_settings = smtp_settings.empty? ? default_smtp_settings : smtp_settings
  end

  def call
    begin
      Mail.deliver do
        to @to
        from @from
        subject @subject
        body @body
      end
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      true
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def default_smtp_settings
    {
      address: ENV['SMTP_ADDRESS'],
      port: ENV['SMTP_PORT'],
      domain: ENV['SMTP_DOMAIN'],
      user_name: ENV['SMTP_USERNAME'],
      password: ENV['SMTP_PASSWORD'],
      authentication: :login,
      enable_starttls_auto: true
    }
  end
end