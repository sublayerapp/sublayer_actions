require 'google/apis/gmail_v1'

# Description: Sublayer::Action responsible for sending emails using the Gmail API.
# This action allows for integration with Gmail, enabling automated email workflows.
#
# Requires: `google-api-client` gem
# $ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile
#
# It is initialized with recipient_email, subject, and body.
# It returns the message ID of the sent email.
#
# Example usage: When you want to send automated emails based on AI-generated content or triggers.

class GmailSendEmailAction < Sublayer::Actions::Base
  def initialize(recipient_email:, subject:, body:)
    @recipient_email = recipient_email
    @subject = subject
    @body = body
    @gmail = Google::Apis::GmailV1::GmailService.new
    @gmail.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/gmail.send'])
  end

  def call
    begin
      message = build_message
      result = @gmail.send_user_message('me', message)
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}, Message ID: #{result.id}")
      result.id
    rescue Google::Apis::ClientError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def build_message
    message = Mail.new
    message.to = @recipient_email
    message.subject = @subject
    message.body = @body
    message
  end

end