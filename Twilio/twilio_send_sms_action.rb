require 'twilio-ruby'

# Description: Sublayer::Action for sending SMS messages using the Twilio API.
# This action sends a text message to a specified recipient, which can be used for notifications
# or alerts triggered by AI processes.
#
# Requires: 'twilio-ruby' gem
# $ gem install twilio-ruby
# Or add `gem 'twilio-ruby'` to your Gemfile
#
# It is initialized with a from_phone, to_phone, and message.
# It returns the SID of the sent message to confirm it was sent successfully.
#
# Example usage: When you want to send an SMS notification from an AI process.

class TwilioSendSMSAction < Sublayer::Actions::Base
  def initialize(from_phone:, to_phone:, message:)
    @from_phone = from_phone
    @to_phone = to_phone
    @message = message
    @client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
  end

  def call
    begin
      response = @client.messages.create(
        from: @from_phone,
        to: @to_phone,
        body: @message
      )
      Sublayer.configuration.logger.log(:info, "SMS sent successfully to #{@to_phone}")
      response.sid
    rescue Twilio::REST::RestError => e
      error_message = "Error sending SMS: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
