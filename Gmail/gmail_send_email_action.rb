require 'google/apis/gmail_v1'
require 'base64'

# Description: Sublayer::Action responsible for sending emails via Gmail API.
# This action allows sending emails with support for plain text or HTML content,
# attachments, and CC/BCC recipients.
#
# Requires: 'google-api-client' gem
# $ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile
#
# Configuration:
# - Requires a Gmail API credentials file path in ENV['GMAIL_CREDENTIALS_PATH']
# - Requires the Gmail API to be enabled in Google Cloud Console
#
# It is initialized with recipient(s), subject, and body, with optional parameters for
# HTML content, CC, BCC, and file attachments.
# It returns the message ID of the sent email.
#
# Example usage: When you want to send automated emails with AI-generated content
# or notifications based on AI analysis.

class GmailSendEmailAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, html_body: nil, cc: [], bcc: [], attachments: [])
    @to = Array(to)
    @subject = subject
    @body = body
    @html_body = html_body
    @cc = Array(cc)
    @bcc = Array(bcc)
    @attachments = Array(attachments)
    
    @service = initialize_gmail_service
  end

  def call
    begin
      message = create_message
      result = @service.send_user_message('me', message)
      
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to.join(', ')}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Failed to send email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def initialize_gmail_service
    service = Google::Apis::GmailV1::GmailService.new
    service.authorization = Google::Auth::ServiceAccountCredentials.from_env(
      scope: 'https://www.googleapis.com/auth/gmail.send'
    )
    service
  end

  def create_message
    message = Google::Apis::GmailV1::Message.new
    message.raw = Base64.urlsafe_encode64(build_mail.to_s)
    message
  end

  def build_mail
    mail = Mail.new
    mail.to = @to
    mail.cc = @cc unless @cc.empty?
    mail.bcc = @bcc unless @bcc.empty?
    mail.subject = @subject
    
    if @html_body
      mail.html_part do
        content_type 'text/html; charset=UTF-8'
        body @html_body
      end
      mail.text_part do
        body @body
      end
    else
      mail.body = @body
    end

    add_attachments(mail)
    mail
  end

  def add_attachments(mail)
    @attachments.each do |attachment|
      if File.exist?(attachment)
        mail.add_file(attachment)
      else
        Sublayer.configuration.logger.log(:warn, "Attachment not found: #{attachment}")
      end
    end
  end
end