require 'mail'

# Description: Sublayer::Action responsible for sending emails.
# This action allows for easy integration of email functionality into Sublayer workflows,
# enabling automated notifications, reports, or communication based on AI-driven processes.
#
# Requires: 'mail' gem
# $ gem install mail
# Or add `gem 'mail'` to your Gemfile
#
# It is initialized with recipient(s), subject, body, and optional attachments.
# It returns a boolean indicating whether the email was sent successfully.
#
# Example usage: When you want to send an email with AI-generated content or as part of an automated workflow.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, from: nil, attachments: [])
    @to = to
    @subject = subject
    @body = body
    @from = from || ENV['DEFAULT_EMAIL_FROM']
    @attachments = attachments
  end

  def call
    begin
      mail = Mail.new
      mail.to = @to
      mail.from = @from
      mail.subject = @subject
      mail.body = @body

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

  private

  def setup_mail_defaults
    Mail.defaults do
      delivery_method :smtp, {
        address: ENV['SMTP_SERVER'],
        port: ENV['SMTP_PORT'],
        user_name: ENV['SMTP_USERNAME'],
        password: ENV['SMTP_PASSWORD'],
        authentication: 'plain',
        enable_starttls_auto: true
      }
    end
  end
end