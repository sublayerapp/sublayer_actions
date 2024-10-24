require 'google/apis/gmail_v1'

# Description: Sublayer::Action responsible for sending emails using the Gmail API.
# It can be used for automated email responses, sending reports, or notifications.
#
# Requires: `google-api-client` gem
# $ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile
#
# It is initialized with the recipient's email address, email subject, and email body.
# It returns the message ID of the sent email to confirm it was sent successfully.
#
# Example usage: When you want to send an automated email response, report, or notification
# from an AI process.
class GmailSendEmailAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:)
    @to = to
    @subject = subject
    @body = body
    @service = Google::Apis::GmailV1::GmailService.new
    @service.client_options.application_name = 'Sublayer AI'
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

      response = @service.send_user_message('me', message)

      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to} with message ID: #{response.id}")
      response.id
    rescue Google::Apis::ClientError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end

  private

  def create_message
    mail = <<~EOF
      From: me
      To: #{@to}
      Subject: #{@subject}

      #{@body}
    EOF

    mail.gsub(/^ +/, '').encode('UTF-8').gsub(/
/, '\n').gsub(/
/, '\r\n').dump
  end
end