require 'twilio-ruby'

# Description: Sublayer::Action responsible for sending an SMS message using Twilio's API.
# This action is ideal for sending notifications and alerts.
#
# It is initialized with a Twilio account_sid, auth_token, from number, to number, and message body.
# It returns the SID of the sent message to confirm it was sent successfully.
#
# Example usage: When you want to send an alert or notification via SMS for an AI-driven process.

class TwilioSMSSendAction < Sublayer::Actions::Base
  def initialize(account_sid:, auth_token:, from:, to:, body:)
    @account_sid = account_sid
    @auth_token = auth_token
    @from = from
    @to = to
    @body = body
    @client = Twilio::REST::Client.new(@account_sid, @auth_token)
  end

  def call
    begin
      message = @client.messages.create(
        from: @from,
        to: @to,
        body: @body
      )
      Sublayer.configuration.logger.log(:info, "Message sent successfully with SID: #{message.sid}")
      message.sid
    rescue Twilio::REST::RestError => e
      error_message = "Error sending SMS via Twilio: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
