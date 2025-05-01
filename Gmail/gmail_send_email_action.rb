require 'google/apis/gmail_v1'

# Description: Sublayer::Action responsible for sending emails using the Gmail API.
# This action enables seamless integration with Gmail for various tasks like sending notifications or reports.
#
# Requires: 'google-api-client' gem
# \$ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile
#
# It is initialized with sender, recipient, subject, and body parameters.
# It returns the message ID of the sent email to confirm successful delivery.
#
# Example usage: When you want to send an email notification or report from an AI process within your Sublayer workflow.

class GmailSendEmailAction < Sublayer::Actions::Base
  def initialize(sender:, recipient:, subject:, body:)
    @sender = sender
    @recipient = recipient
    @subject = subject
    @body = body
    @service = Google::Apis::GmailV1::GmailService.new
    @service.client_options.application_name = 'Sublayer'
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      scope: 'https://www.googleapis.com/auth/gmail.send',
      path: ENV['GOOGLE_APPLICATION_CREDENTIALS']
    )
  end

  def call
    begin
      message = Google::Apis::GmailV1::Message.new(
        raw: create_message
      )
      @service.send_user_message('me', message)
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient}")
      message.id
    rescue Google::Apis::ClientError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_message
    mail = Mail.new do
      from @sender
      to @recipient
      subject @subject
      body @body
    end
    mail.to_s.encode('UTF-8')
  end
end