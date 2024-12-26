require 'twilio-ruby'

# Description: Sublayer::Action responsible for sending SMS messages via Twilio.
# This action is useful for workflows needing mobile notifications based on AI results or updates.
#
# Requires: 'twilio-ruby' gem
# $ gem install twilio-ruby
# Or add `gem 'twilio-ruby'` to your Gemfile
#
# It is initialized with to, from, and body parameters for SMS.
# It returns the SID of the sent message to verify successful delivery.
#
# Example usage: Send alerts or status updates to a mobile device as part of an automated workflow.

class TwilioSMSSenderAction < Sublayer::Actions::Base
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
    rescue Twilio::REST::TwilioError => e
      error_message = "Error sending SMS via Twilio: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
