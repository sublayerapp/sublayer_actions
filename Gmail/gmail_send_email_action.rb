require 'google/apis/gmail_v1'

# Description: Sublayer::Action responsible for sending emails via the Gmail API.
# Useful for automating email communications within workflows.
#
# It is initialized with recipient, subject, and body. Optional attachments are supported
#
# Example usage: Sending email notifications or updates from an AI-driven process.

class GmailSendEmailAction < Sublayer::Actions::Base
  def initialize(recipient:, subject:, body:, attachments: [])
    @recipient = recipient
    @subject = subject
    @body = body
    @attachments = attachments

    @service = Google::Apis::GmailV1::GmailService.new
    @service.client_options.application_name = 'Sublayer Actions'
    @service.authorize(credentials: get_credentials)
  end

  def call
    begin
      message = build_message
      @service.send_user_message('me', message)
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient}")
    rescue Google::Apis::ClientError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def get_credentials
    # Implement your preferred method of credential retrieval
    # Example using environment variables:
    Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(ENV['GOOGLE_CLIENT_SECRET']),
      scope: 'https://www.googleapis.com/auth/gmail.send'
    )
  end

  def build_message
    mail = Mail.new
    mail.from = 'me'
    mail.to = @recipient
    mail.subject = @subject
    mail.text_part = Mail::Part.new do
      content_type 'text/plain; charset=UTF-8'
      body @body
    end

    @attachments.each do |attachment|
      mail.add_file attachment
    end

    message = Google::Apis::GmailV1::Message.new
    message.raw = mail.to_s.encode('ASCII-8BIT')
    message
  end
end