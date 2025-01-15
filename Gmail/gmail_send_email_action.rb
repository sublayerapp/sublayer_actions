require 'google/apis/gmail_v1'

# Description: Sublayer::Action responsible for sending emails using the Gmail API.
# This action allows integration with Gmail for sending email notifications or updates from AI-driven processes.
#
# Requires: `google-api-client` gem
# $ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile
#
# It is initialized with recipient_email, sender_email, subject, and email_body.
# It returns the message ID of the sent email to confirm it was sent successfully.
#
# Example usage: When you want to send an email notification from an AI process.

class GmailSendEmailAction < Sublayer::Actions::Base
  def initialize(recipient_email:, sender_email:, subject:, email_body:)
    @recipient_email = recipient_email
    @sender_email = sender_email
    @subject = subject
    @email_body = email_body

    @gmail = Google::Apis::GmailV1::GmailService.new
    @gmail.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/gmail.send'])
  end

  def call
    begin
      message = Google::Apis::GmailV1::Message.new(
        raw: create_email_raw
      )

      result = @gmail.send_user_message('me', message)

      Sublayer.configuration.logger.log(:info, "Message sent successfully to #{@recipient_email}, ID: #{result.id}")
      result.id
    rescue Google::Apis::ClientError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_email_raw
    message = Mail.new
    message.to = @recipient_email
    message.from = @sender_email
    message.subject = @subject
    message.body = @email_body
    message.encoded
  end
end