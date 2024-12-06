require 'googleauth'
require 'gmail'

# Description: Sublayer::Action responsible for sending emails using the Gmail API.
# Useful for automating email communication from AI agents.
#
# It is initialized with recipient_email, subject, and body.
# It returns the message ID of the sent email or raises an error if unsuccessful.
#
# Example usage: When you want an AI agent to send emails based on certain conditions or events.

class GmailSendMessageAction < Sublayer::Actions::Base
  def initialize(recipient_email:, subject:, body:)
    @recipient_email = recipient_email
    @subject = subject
    @body = body

    scopes = [
      'https://www.googleapis.com/auth/gmail.send'
    ]

    authorization = Google::Auth.get_application_default(scopes)
    @gmail = Gmail.new(authorization)
  end

  def call
    begin
      message = @gmail.compose do
        to @recipient_email
        subject @subject
        text_part do
          body @body
        end
      end

      response = @gmail.deliver(message)

      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}, message ID: #{response.id}")
      response.id
    rescue Google::Apis::ClientError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Unexpected error: #{e.message}")
      raise e
    end
  end
end