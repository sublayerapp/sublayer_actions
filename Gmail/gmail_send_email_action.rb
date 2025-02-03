require 'googleauth'
require 'google/apis/gmail_v1'

# Description: Sublayer::Action responsible for sending emails using the Gmail API.
# This action allows for integration with Gmail, enabling automated email communication within Sublayer workflows.
#
# It is initialized with recipient_address, subject, and body.
# It returns the success/failure status.
#
# Example usage: When you want to send an email notification or update from an AI process.

class GmailSendEmailAction < Sublayer::Actions::Base
  def initialize(recipient_address:, subject:, body:)
    @recipient_address = recipient_address
    @subject = subject
    @body = body

    # Initialize the Gmail API client
    @service = Google::Apis::GmailV1::GmailService.new
    @service.client_options.application_name = 'Sublayer'
    scopes = [Google::Apis::GmailV1::AUTH_GMAIL_SEND]
    authorization = Google::Auth.get_application_default(scopes)
    @service.authorization = authorization
  end

  def call
    begin
      message = build_message
      send_message(message)
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_address}")
      return true  # Indicate success
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      return false # Indicate failure
    end
  end

  private

  def build_message
    mail = Mail.new
    mail.to = @recipient_address
    mail.from = ENV['GMAIL_SENDER_ADDRESS'] || 'me'
    mail.subject = @subject
    mail.body = @body
    encoded_message = mail.to_s.gsub(/
/, '\r\n').gsub(/
/, '\n')
    Google::Apis::GmailV1::Message.new(raw: Base64.urlsafe_encode64(encoded_message))
  end

  def send_message(message)
    @service.send_user_message('me', message)
  end
end