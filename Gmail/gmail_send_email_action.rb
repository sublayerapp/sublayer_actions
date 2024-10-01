require "google/apis/gmail_v1"

# Description: This Sublayer::Action utilizes the Gmail API to send an email.
# It handles authentication, recipient email address, subject, body, and attachments.

class GmailSendEmailAction < Sublayer::Actions::Base
  def initialize(recipient_email:, subject:, body:, attachments: [], credentials_path: ENV["GOOGLE_APPLICATION_CREDENTIALS"])
    @recipient_email = recipient_email
    @subject = subject
    @body = body
    @attachments = attachments
    @credentials_path = credentials_path
  end

  def call
    service = authorize
    message = build_message
    send_message(service, message)
  end

  private

  def authorize
    service = Google::Apis::GmailV1::GmailService.new
    scopes = [Google::Apis::GmailV1::AUTH_GMAIL_SEND]
    service.client_options.application_name = "Sublayer Action"
    service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      scope: scopes,
      path: @credentials_path
    )
    service
  rescue StandardError => e
    Sublayer.logger.error("Error authorizing Gmail client: #{e.message}")
    raise e
  end

  def build_message
    message = Mail.new
    message.from = "sublayer-actions@example.com"
    message.to = @recipient_email
    message.subject = @subject
    message.text_part = @body

    @attachments.each do |attachment_path|
      message.add_file(attachment_path)
    end

    message
  end

  def send_message(service, message)
    encoded_message = Base64.urlsafe_encode64(message.to_s)
    message_object = Google::Apis::GmailV1::Message.new(raw: encoded_message)
    service.send_user_message("me", message_object)
  rescue StandardError => e
    Sublayer.logger.error("Error sending email: #{e.message}")
    raise e
  end
end