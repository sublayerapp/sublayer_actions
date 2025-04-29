require 'twilio-ruby'

# Description: Sublayer::Action responsible for sending an SMS to a specified phone number using Twilio.
# This action is intended for sending alerts, reminders, or notifications directly to users' mobile devices.
#
# It is initialized with a phone_number and message. Upon successful execution, it sends the SMS and returns the message SID for confirmation.
#
# Example usage: When you want to send a notification or alert from an AI process to a mobile device.

class TwilioSendSMSAction < Sublayer::Actions::Base
  def initialize(phone_number:, message:)
    @phone_number = phone_number
    @message = message
    @client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
    @from_number = ENV['TWILIO_FROM_NUMBER']
  end

  def call
    begin
      message = @client.messages.create(
        from: @from_number,
        to: @phone_number,
        body: @message
      )
      Sublayer.configuration.logger.log(:info, "SMS sent successfully to #{@phone_number}. Message SID: #{message.sid}")
      message.sid
    rescue Twilio::REST::RestError => e
      error_message = "Error sending SMS: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
