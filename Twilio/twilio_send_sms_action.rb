require 'twilio-ruby'

# Description: Sublayer::Action responsible for sending an SMS message using Twilio.
# This action is useful for sending alerts or notifications from AI-driven workflows.
#
# It is initialized with the recipient's phone number and message content.
# It returns the sid of the sent message to confirm that it was sent successfully.
#
# Example usage: When you want to send an alert to a user via SMS as part of a Sublayer workflow.

class TwilioSendSMSAction < Sublayer::Actions::Base
  def initialize(to:, body:, from: ENV['TWILIO_PHONE_NUMBER'])
    @to = to
    @body = body
    @from = from
    @client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
  end

  def call
    begin
      message = @client.messages.create(
        from: @from,
        to: @to,
        body: @body
      )
      Sublayer.configuration.logger.log(:info, "Message sent successfully to #{@to} with SID: #{message.sid}")
      message.sid
    rescue Twilio::REST::TwilioError => e
      error_message = "Error sending SMS via Twilio: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
