require 'mail'

# Description: Sublayer::Action responsible for generating and sending email summaries to specified contacts.
# It can be used in workflows for notifying team members about updates or results generated from AI tasks.
#
# Requires: 'mail' gem
# $ gem install mail
# Or add `gem 'mail'` to your Gemfile
#
# It is initialized with recipients (a list of email addresses), subject, and body.
# It sends an email using the SMTP settings defined in the environment variables.
#
# Example usage: When you want to send a summary of AI-generated results to a team via email.

class EmailSummaryServiceAction < Sublayer::Actions::Base
  def initialize(recipients:, subject:, body:)
    @recipients = recipients
    @subject = subject
    @body = body
    configure_mail
  end

  def call
    send_email_summary
  rescue Mail::Field::ParseError => e
    error_message = "Error parsing email fields: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error sending email summary: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def configure_mail
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

  def send_email_summary
    Mail.deliver do
      from    ENV['SMTP_FROM_ADDRESS']
      to      @recipients
      subject @subject
      body    @body
    end
    Sublayer.configuration.logger.log(:info, "Email summary sent successfully to #{@recipients.join(', ')}")
  end
end
