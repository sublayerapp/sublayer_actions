require 'google/apis/gmail_v1'
require 'googleauth'
require 'mail'

# Description: Sublayer::Action responsible for sending emails via Gmail API.
# This action allows sending emails with support for HTML content, attachments, and multiple recipients.
#
# Requires: 'google-api-client' and 'mail' gems
# $ gem install google-api-client mail
# Or add to your Gemfile:
# gem 'google-api-client'
# gem 'mail'
#
# Also requires Gmail API credentials stored in environment variables:
# GMAIL_CLIENT_ID, GMAIL_CLIENT_SECRET, GMAIL_REFRESH_TOKEN
#
# It is initialized with recipient(s), subject, and body (plain text or HTML).
# Optionally accepts CC, BCC, and file attachments.
# Returns the message ID of the sent email.
#
# Example usage: When you want to send AI-generated reports, notifications,
# or follow up on automated analysis via email.

class GmailSendEmailAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, html: false, cc: nil, bcc: nil, attachments: [])
    @to = Array(to)  # Convert single recipient to array
    @subject = subject
    @body = body
    @html = html
    @cc = Array(cc) if cc
    @bcc = Array(bcc) if bcc
    @attachments = attachments
    setup_gmail_service
  end

  def call
    begin
      message = create_email_message
      result = send_email(message)
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

  def setup_gmail_service
    @service = Google::Apis::GmailV1::GmailService.new
    authorizer = Google::Auth::UserRefreshCredentials.new(
      client_id: ENV['GMAIL_CLIENT_ID'],
      client_secret: ENV['GMAIL_CLIENT_SECRET'],
      refresh_token: ENV['GMAIL_REFRESH_TOKEN'],
      scope: ['https://www.googleapis.com/auth/gmail.send']
    )
    @service.authorization = authorizer
  end

  def create_email_message
    mail = Mail.new
    mail.to = @to
    mail.cc = @cc if @cc
    mail.bcc = @bcc if @bcc
    mail.subject = @subject

    if @html
      mail.html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body @body
      end
    else
      mail.text_part = Mail::Part.new do
        body @body
      end
    end

    # Add attachments if any
    @attachments.each do |attachment|
      mail.add_file(attachment)
    end

    # Encode the mail object to Gmail API format
    message = Google::Apis::GmailV1::Message.new(
      raw: Base64.urlsafe_encode64(mail.to_s)
    )
    message
  end

  def send_email(message)
    @service.send_user_message('me', message)
  end
end