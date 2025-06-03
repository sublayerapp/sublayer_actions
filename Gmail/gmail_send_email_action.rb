require 'google/apis/gmail_v1'
require 'base64'

# Description: Sublayer::Action responsible for sending emails through Gmail API.
# This action enables automated email communications with support for HTML formatting,
# attachments, and CC/BCC recipients.
#
# Requires: 'google-api-client' gem
# $ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile
#
# Additionally requires Gmail API credentials set up in Google Cloud Console
# and the following environment variables:
# - GMAIL_CLIENT_ID
# - GMAIL_CLIENT_SECRET
# - GMAIL_REFRESH_TOKEN
#
# It is initialized with recipient email(s), subject, and body content.
# Optionally accepts CC, BCC, and file attachments.
# Returns the message ID of the sent email.
#
# Example usage: When you want to send automated emails with AI-generated content,
# such as notifications, reports, or responses to queries.

class GmailSendEmailAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, cc: nil, bcc: nil, attachments: nil, html: false)
    @to = Array(to)
    @cc = Array(cc) if cc
    @bcc = Array(bcc) if bcc
    @subject = subject
    @body = body
    @html = html
    @attachments = attachments || []
    
    setup_gmail_service
  end

  def call
    begin
      message = create_message
      result = @service.send_user_message('me', message)
      
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to.join(', ')}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Failed to send Gmail message: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def setup_gmail_service
    @service = Google::Apis::GmailV1::GmailService.new
    @service.authorization = Google::Auth::UserRefreshCredentials.new(
      client_id: ENV['GMAIL_CLIENT_ID'],
      client_secret: ENV['GMAIL_CLIENT_SECRET'],
      refresh_token: ENV['GMAIL_REFRESH_TOKEN'],
      scope: ['https://www.googleapis.com/auth/gmail.send']
    )
  end

  def create_message
    message = RMail::Message.new
    message.header['To'] = @to.join(', ')
    message.header['Subject'] = @subject
    
    if @cc
      message.header['Cc'] = @cc.join(', ')
    end

    if @bcc
      message.header['Bcc'] = @bcc.join(', ')
    end

    if @html
      message.header['Content-Type'] = 'text/html; charset=UTF-8'
      message.body = @body
    else
      message.header['Content-Type'] = 'text/plain; charset=UTF-8'
      message.body = @body
    end

    if @attachments.any?
      message = add_attachments(message)
    end

    encoded_message = Base64.urlsafe_encode64(message.to_s)

    Google::Apis::GmailV1::Message.new(raw: encoded_message)
  end

  def add_attachments(message)
    message = RMail::Message.new
    message.header['Content-Type'] = 'multipart/mixed'

    @attachments.each do |attachment|
      part = RMail::Message.new
      filename = File.basename(attachment)
      content = File.read(attachment)
      
      part.header['Content-Type'] = 'application/octet-stream'
      part.header['Content-Disposition'] = "attachment; filename=\"#{filename}\""
      part.header['Content-Transfer-Encoding'] = 'base64'
      part.body = Base64.encode64(content)

      message.add_part(part)
    end

    message
  end
end