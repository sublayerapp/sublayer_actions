require 'twilio-ruby'

# Description: Sublayer::Action responsible for sending an SMS message via Twilio's API.
# This action is useful for sending notifications and alerts to users.
#
# It is initialized with a recipient phone number, a message, and optionally a sender phone number.
# It returns a status message indicating if the SMS was sent successfully.
#
# Example usage: When you want to send a notification or alert to a user's phone via SMS.

class TwilioSendSMSAction < Sublayer::Actions::Base
  def initialize(to:, message:, from: nil)
    @to = to
    @message = message
    @from = from || ENV['TWILIO_PHONE_NUMBER']
    @account_sid = ENV['TWILIO_ACCOUNT_SID']
    @auth_token = ENV['TWILIO_AUTH_TOKEN']
    @client = Twilio::REST::Client.new(@account_sid, @auth_token)
  end

  def call
    begin
      message = @client.messages.create(
        from: @from,
        to: @to,
        body: @message
      )
      Sublayer.configuration.logger.log(:info, "SMS sent successfully to #{@to}")
      message.status
    rescue Twilio::REST::RestError => e
      error_message = "Error sending SMS: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
