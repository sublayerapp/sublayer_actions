require 'twilio-ruby'

# Description: Sublayer::Action responsible for sending SMS messages using Twilio API.
# This action is helpful for sending alerts or notifications through text messages.
#
# It is initialized with a 'to', 'from', and 'body'.
# It returns the message SID to confirm it was sent successfully.
#
# Example usage: When you want to send an SMS alert from an AI-driven process.

class TwilioSmsSendAction < Sublayer::Actions::Base
  def initialize(to:, from:, body:)
    @to = to
    @from = from
    @body = body
    @client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
  end

  def call
    begin
      message = @client.messages.create(
        body: @body,
        from: @from,
        to: @to
      )
      Sublayer.configuration.logger.log(:info, "SMS sent successfully to \\#{@to} with SID \\#{message.sid}")
      message.sid
    rescue Twilio::REST::TwilioError => e
      error_message = "Error sending SMS: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
