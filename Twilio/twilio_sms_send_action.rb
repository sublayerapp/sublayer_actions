require 'twilio-ruby'

# Description: Sublayer::Action responsible for sending an SMS message to a specified phone number using Twilio's service.
# This action can be used for delivering notifications or alerts via SMS as part of a Sublayer workflow.
#
# It is initialized with a phone number and a message body.
# It returns the SID of the sent message to confirm it was sent successfully.
#
# Example usage: When you want to send a notification or alert from an AI process as an SMS.

class TwilioSMSSendAction < Sublayer::Actions::Base
  def initialize(phone_number:, message_body:)
    @phone_number = phone_number
    @message_body = message_body

    account_sid = ENV['TWILIO_ACCOUNT_SID']
    auth_token = ENV['TWILIO_AUTH_TOKEN']

    @client = Twilio::REST::Client.new(account_sid, auth_token)
  end

  def call
    begin
      message = @client.messages.create(
        body: @message_body,
        to: @phone_number,
        from: ENV['TWILIO_PHONE_NUMBER'] # Ensure this environment variable is set to your Twilio number
      )
      Sublayer.configuration.logger.log(:info, "Message sent successfully to #{@phone_number}")
      message.sid
    rescue Twilio::REST::RestError => e
      Sublayer.configuration.logger.log(:error, "Error sending SMS message: #{e.message}")
      raise StandardError, "Failed to send SMS: #{e.message}"
    end
  end
end
