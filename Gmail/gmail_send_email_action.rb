require 'google/apis/gmail_v1'
require 'mail'

# Description: Sublayer::Action responsible for sending emails through Gmail using the Gmail API.
# This action allows for sending emails with support for HTML content, attachments, and multiple recipients.
#
# Requires: 'google-api-client' and 'mail' gems
# $ gem install google-api-client mail
# Or add to your Gemfile:
# gem 'google-api-client'
# gem 'mail'
#
# It is initialized with required email parameters and optionally attachments.
# It returns the message ID of the sent email to confirm successful delivery.
#
# Example usage: When you want to send automated email responses or notifications
# with AI-generated content through Gmail.

class GmailSendEmailAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, from: nil, cc: nil, bcc: nil, html_content: false, attachments: [])
    @to = Array(to)
    @subject = subject
    @body = body
    @from = from || ENV['GMAIL_SENDER_EMAIL']
    @cc = Array(cc) if cc
    @bcc = Array(bcc) if bcc
    @html_content = html_content
    @attachments = attachments
    
    @service = Google::Apis::GmailV1::GmailService.new
    @service.authorization = authorize
  end

  def call
    begin
      message = create_email
      result = @service.send_user_message('me',
        upload_source: StringIO.new(message.to_s),
        content_type: 'message/rfc822')
      
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to.join(', ')}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Gmail API error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def authorize
    # Implement your preferred Google OAuth2 authorization method here
    # This could use service account credentials or user OAuth2 tokens
    credentials = Google::Auth::ServiceAccountCredentials.from_env(
      scope: ['https://www.googleapis.com/auth/gmail.send']
    )
    credentials.fetch_access_token!
    credentials
  end

  def create_email
    mail = Mail.new
    mail.from = @from
    mail.to = @to
    mail.cc = @cc if @cc
    mail.bcc = @bcc if @bcc
    mail.subject = @subject

    if @html_content
      mail.html_part = Mail::Part.new
      mail.html_part.content_type = 'text/html; charset=UTF-8'
      mail.html_part.body = @body
    else
      mail.text_part = Mail::Part.new
      mail.text_part.body = @body
    end

    # Add attachments if any
    @attachments.each do |attachment|
      mail.add_file(attachment)
    end

    mail
  end
end