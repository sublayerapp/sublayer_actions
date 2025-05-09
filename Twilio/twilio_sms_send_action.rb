require 'twilio-ruby'

# Description: Sublayer::Action responsible for sending SMS notifications using Twilio.
# This action is useful for workflows that require real-time user notifications or verification codes.
#
# It is initialized with a phone number and a message. Returns the SID of the message to confirm it was sent successfully.
#
# Example usage: Use this action when you need to send out verification codes or notifications to users via SMS.
class TwilioSmsSendAction < Sublayer::Actions::Base
  def initialize(to:, message:, **kwargs)
    super(**kwargs)
    @to = to
    @message = message
    @from = ENV['TWILIO_PHONE_NUMBER']
    @client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
  end

  def call
    begin
      message = @client.messages.create(
        from: @from,
        to: @to,
        body: @message
      )
      Sublayer.configuration.logger.log(:info, "SMS sent successfully to #{@to}. Message SID: "+ message.sid)
      message.sid
    rescue Twilio::REST::RestError => e
      error_message = "Error sending SMS: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end