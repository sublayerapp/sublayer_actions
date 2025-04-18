require 'google/apis/gmail_v1'
require 'mail'
require 'base64'

# Description: Sublayer::Action responsible for sending emails through Gmail.
# This action enables sending emails with HTML content, attachments, and CC/BCC recipients.
#
# Requires: 'google-api-client' and 'mail' gems
# $ gem install google-api-client mail
# Or add to your Gemfile:
# gem 'google-api-client'
# gem 'mail'
#
# It is initialized with required email parameters and uses Gmail API for sending.
# Returns the message ID of the sent email on success.
#
# Example usage: When you want to send automated but personalized email communications
# as part of an AI workflow, such as sending AI-generated reports or notifications.

class GmailSendEmailAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, html: false, cc: nil, bcc: nil, attachments: [])
    @to = to
    @subject = subject
    @body = body
    @html = html
    @cc = cc
    @bcc = bcc
    @attachments = attachments
    
    # Initialize Gmail API client
    @gmail = Google::Apis::GmailV1::GmailService.new
    @gmail.authorization = google_credentials
  end

  def call
    begin
      message = create_message
      result = send_message(message)
      
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
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

  def google_credentials
    # Assumes credentials are configured using environment variables
    # or application default credentials
    Google::Auth.get_application_default(['https://www.googleapis.com/auth/gmail.send'])
  end

  def create_message
    mail = Mail.new
    mail.to = @to
    mail.subject = @subject
    mail.from = ENV['GMAIL_SENDER_EMAIL']
    
    # Add CC and BCC recipients if provided
    mail.cc = @cc if @cc
    mail.bcc = @bcc if @bcc

    # Set up the email body (plain text or HTML)
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

    # Create the Gmail API message format
    message = Google::Apis::GmailV1::Message.new(
      raw: Base64.urlsafe_encode64(mail.to_s)
    )
  end

  def send_message(message)
    @gmail.send_user_message('me', message)
  end
end