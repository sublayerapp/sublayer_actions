require 'google/apis/gmail_v1'
require 'mail'
require 'base64'

# Description: Sublayer::Action responsible for sending emails through Gmail.
# This action enables sending formatted emails with HTML content, attachments, and CC/BCC recipients
# as part of AI-driven workflows.
#
# Requires: 'google-api-client' and 'mail' gems
# $ gem install google-api-client mail
# Or add to your Gemfile:
# gem 'google-api-client'
# gem 'mail'
#
# It is initialized with email parameters including recipients, subject, body, and optional attachments.
# It returns the message ID of the sent email to confirm successful delivery.
#
# Example usage: When you want an AI agent to send formatted email communications
# as part of automated workflows or in response to specific triggers.

class EmailSendGmailAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, html_body: nil, cc: nil, bcc: nil, attachments: [])
    @to = to
    @subject = subject
    @body = body
    @html_body = html_body
    @cc = cc
    @bcc = bcc
    @attachments = attachments
    
    # Initialize Gmail API client
    @gmail = Google::Apis::GmailV1::GmailService.new
    @gmail.authorization = authorize
  end

  def call
    begin
      message = create_email
      result = @gmail.send_user_message('me',
        upload_source: StringIO.new(message.encoded),
        content_type: 'message/rfc822')
      
      Sublayer.configuration.logger.log(:info, "Email sent successfully with message ID: #{result.id}")
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
    # Assumes credentials are loaded from a JSON file
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GMAIL_CREDENTIALS_PATH']),
      scope: 'https://www.googleapis.com/auth/gmail.send'
    )
    authorizer.fetch_access_token!
    authorizer
  end

  def create_email
    mail = Mail.new
    mail.to = @to
    mail.cc = @cc if @cc
    mail.bcc = @bcc if @bcc
    mail.subject = @subject
    mail.from = ENV['GMAIL_SENDER_ADDRESS']

    if @html_body
      mail.html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body @html_body
      end
      mail.text_part = Mail::Part.new do
        body @body
      end
    else
      mail.body = @body
    end

    # Add attachments if any
    @attachments.each do |attachment|
      mail.add_file(attachment)
    end

    mail
  end
end