require 'mail'

# Description: Sublayer::Action responsible for sending emails using various email providers.
# This action provides a general-purpose email sending capability that can be used for
# automated notifications, AI-generated reports, or any other email communication needs
# within a Sublayer workflow.
#
# Requires: 'mail' gem
# $ gem install mail
# Or add `gem 'mail'` to your Gemfile
#
# It is initialized with recipient email, subject, body, and optional parameters for CC, BCC, and attachments.
# It returns a boolean indicating whether the email was sent successfully.
#
# Example usage: When you want to send an email with AI-generated content or as part of an automated workflow.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, from: nil, cc: nil, bcc: nil, attachments: [])
    @to = to
    @subject = subject
    @body = body
    @from = from || ENV['DEFAULT_FROM_EMAIL']
    @cc = cc
    @bcc = bcc
    @attachments = attachments
    
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

  def call
    begin
      mail = Mail.new
      mail.to = @to
      mail.from = @from
      mail.subject = @subject
      mail.body = @body
      
      mail.cc = @cc if @cc
      mail.bcc = @bcc if @bcc
      
      @attachments.each do |attachment|
        mail.add_file(attachment)
      end
      
      mail.deliver!
      
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      true
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end