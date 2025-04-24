require 'googleauth'
require 'google/apis/gmail_v1'

# Description: Sublayer::Action responsible for sending emails using the Gmail API.
# This action allows for integration with Gmail, enabling automated email communication within Sublayer workflows.
#
# Requires: `googleauth` and `google/apis/gmail_v1` gems
# $ gem install googleauth google-api-client
# Or add `gem 'googleauth'` and `gem 'google-api-client'` to your Gemfile
#
# It is initialized with recipient emails, subject, body, and optional attachments.
# It returns a success status upon successful sending or raises an error with a message.
#
# Example usage: Sending notifications, reports, or other email communications within an AI-driven Sublayer workflow.

class GmailSendEmailAction < Sublayer::Actions::Base
  def initialize(recipients:, subject:, body:, attachments: [])
    @recipients = recipients
    @subject = subject
    @body = body
    @attachments = attachments

    @client = get_gmail_client
  end

  def call
    begin
      message = build_message
      result = @client.send_user_message('me', message)

      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipients.join(', ')}")
      result.id
    rescue Google::Apis::ClientError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def build_message
    message = Google::Apis::GmailV1::Message.new
    raw_message = ""
    raw_message += "To: #{@recipients.join(', ')}"\n"
    raw_message += "Subject: #{@subject}"\n"
    raw_message += "MIME-Version: 1.0\r\n"
    raw_message += "Content-Type: multipart/mixed; boundary=\"=_NextPart_000_0000_01D9F20A.7AC032F0\";\r\n"
    raw_message += "\r\n"
    raw_message += "--=_NextPart_000_0000_01D9F20A.7AC032F0\r\n"
    raw_message += "Content-Type: text/html; charset=UTF-8\r\n"
    raw_message += "Content-Transfer-Encoding: 7bit\r\n"
    raw_message += "\r\n"
    raw_message += "#{@body}\r\n"
    @attachments.each do |attachment|
      raw_message += "--=_NextPart_000_0000_01D9F20A.7AC032F0\r\n"
      raw_message += "Content-Type: application/octet-stream; name=\""
      raw_message += "#{File.basename(attachment)}"\r\n"
      raw_message += "Content-Transfer-Encoding: base64\r\n"
      raw_message += "Content-Disposition: attachment; filename=\""
      raw_message += "#{File.basename(attachment)}"\r\n"
      raw_message += "\r\n"
      raw_message += "#{Base64.strict_encode64(File.read(attachment))}\r\n"
    end
    raw_message += "--=_NextPart_000_0000_01D9F20A.7AC032F0--"

    message.raw = Base64.urlsafe_encode64(raw_message)
    message
  end

  def get_gmail_client
    scopes = ['https://mail.google.com/']
    authorization = Google::Auth.get_application_default(scopes)

    gmail = Google::Apis::GmailV1::GmailService.new
    gmail.authorization = authorization
    gmail
  end
end