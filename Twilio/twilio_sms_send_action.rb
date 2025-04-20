require 'twilio-ruby'

# Description: A Sublayer::Action for sending SMS messages using Twilio.
# This action allows integration with Twilio's API to send SMS messages.
# It is initialized with a recipient's phone number and message content.
# Returns the message SID to confirm successful dispatch.
#
# Example usage: When you want to send an SMS notification via Twilio from a Sublayer workflow.

class TwilioSmsSendAction < Sublayer::Actions::Base
  def initialize(to:, message:)
    @to = to
    @message = message
    @client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
    @from = ENV['TWILIO_PHONE_NUMBER']
  end

  def call
    begin
      message = @client.messages.create(
        from: @from,
        to: @to,
        body: @message
      )
      Sublayer.configuration.logger.log(:info, "SMS sent successfully to #{@to}. Message SID: #{message.sid}")
      message.sid
    rescue Twilio::REST::RestError => e
      error_message = "Error sending SMS to #{@to}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "An unexpected error occurred while sending SMS to #{@to}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end
