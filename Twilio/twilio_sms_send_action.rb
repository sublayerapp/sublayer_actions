require 'twilio-ruby'

# Description: Sublayer::Action responsible for sending SMS messages using Twilio.
# This action is ideal for sending notifications or alerts in Sublayer workflows.
#
# Requires: 'twilio-ruby' gem
# $ gem install twilio-ruby
# Or add `gem 'twilio-ruby'` to your Gemfile
#
# It is initialized with to, from, and body parameters to define the SMS details.
# It returns the message SID to confirm successful sending.
#
# Example usage: When you need to send an SMS notification in response to an event in your workflow.

class TwilioSMSSendAction < Sublayer::Actions::Base
  def initialize(to:, from:, body:)
    @to = to
    @from = from
    @body = body
    @client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
  end

  def call
    begin
      message = @client.messages.create(
        from: @from,
        to: @to,
        body: @body
      )
      Sublayer.configuration.logger.log(:info, "SMS sent successfully to #{@to}")
      message.sid
    rescue Twilio::REST::RestError => e
      error_message = "Error sending SMS: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
