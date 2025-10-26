require 'google/apis/gmail_v1'
require 'googleauth'

# Description: Sublayer::Action responsible for sending emails through Gmail API.
# This action enables automated email sending within Sublayer workflows, supporting
# HTML content, attachments, and CC/BCC functionality.
#
# Requires: 'google-api-client' and 'googleauth' gems
# $ gem install google-api-client googleauth
# Or add to your Gemfile:
# gem 'google-api-client'
# gem 'googleauth'
#
# Also requires Gmail API credentials in the following environment variables:
# - GMAIL_CLIENT_ID
# - GMAIL_CLIENT_SECRET
# - GMAIL_REFRESH_TOKEN
#
# It is initialized with recipient email, subject, and body, with optional CC, BCC, and attachments.
# It returns the message ID of the sent email.
#
# Example usage: When you want to send AI-generated content, automated follow-ups,
# or notifications via email as part of a Sublayer workflow.

class GmailSendEmailAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, cc: nil, bcc: nil, attachments: nil, html: false)
    @to = to
    @subject = subject
    @body = body
    @cc = cc
    @bcc = bcc
    @attachments = attachments
    @html = html
    @service = initialize_gmail_service
  end

  def call
    begin
      message = create_message
      result = @service.send_user_message('me', message)
      
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}. Message ID: #{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error sending Gmail message: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def initialize_gmail_service
    service = Google::Apis::GmailV1::GmailService.new
    authorizer = Google::Auth::UserRefreshCredentials.new(
      client_id: ENV['GMAIL_CLIENT_ID'],
      client_secret: ENV['GMAIL_CLIENT_SECRET'],
      refresh_token: ENV['GMAIL_REFRESH_TOKEN'],
      scope: ['https://www.googleapis.com/auth/gmail.send']
    )
    service.authorization = authorizer
    service
  end

  def create_message
    message = Google::Apis::GmailV1::Message.new
    message.raw = create_email.to_s
    message
  end

  def create_email
    mail = Mail.new
    mail.to = @to
    mail.subject = @subject
    
    # Set CC and BCC if provided
    mail.cc = @cc if @cc
    mail.bcc = @bcc if @bcc

    # Set content type based on html flag
    if @html
      mail.html_part = Mail::Part.new do |part|
        part.content_type 'text/html; charset=UTF-8'
        part.body @body
      end
    else
      mail.text_part = Mail::Part.new do |part|
        part.body @body
      end
    end

    # Add attachments if provided
    if @attachments
      @attachments.each do |attachment|
        mail.add_file(attachment)
      end
    end

    # Set from address to the authenticated user's email
    mail.from = 'me'

    mail
  end
end