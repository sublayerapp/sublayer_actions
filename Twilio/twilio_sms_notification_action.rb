require 'twilio-ruby'

# Description: Sublayer::Action responsible for sending SMS messages using Twilio.
# This action is intended to be used for sending notifications or alerts from AI-driven processes.
#
# It is initialized with account_sid, auth_token, from (Twilio phone number), to (recipient phone number), and message.
# It returns the SID of the sent message to confirm it was sent successfully.
#
# Example usage: When you want to send a notification about task completion or an alert to a user's phone number.

class TwilioSMSNotificationAction < Sublayer::Actions::Base
  def initialize(account_sid:, auth_token:, from:, to:, message:)
    @account_sid = account_sid
    @auth_token = auth_token
    @from = from
    @to = to
    @message = message
    @client = Twilio::REST::Client.new(@account_sid, @auth_token)
  end

  def call
    begin
      message = @client.messages.create(
        from: @from,
        to: @to,
        body: @message
      )
      Sublayer.configuration.logger.log(:info, "SMS sent successfully to #{@to} with SID: #{message.sid}")
      message.sid
    rescue Twilio::REST::TwilioError => e
      error_message = "Error sending SMS: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
