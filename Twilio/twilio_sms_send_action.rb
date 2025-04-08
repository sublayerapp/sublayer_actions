require 'twilio-ruby'

# Description: Sublayer::Action responsible for sending an SMS message using the Twilio API.
# This action can be used to notify users or stakeholders about important updates or events triggered within a workflow.
#
# It is initialized with a message body, recipient phone number, and optional sender phone number.
# It returns the SID of the sent message to confirm it was sent successfully.
#
# Example usage: When you want to send an SMS notification from an AI process to a user or stakeholder.

class TwilioSMSSendAction < Sublayer::Actions::Base
  def initialize(body:, to:, from: nil)
    @body = body
    @to = to
    @from = from || ENV['TWILIO_PHONE_NUMBER']
    @account_sid = ENV['TWILIO_ACCOUNT_SID']
    @auth_token = ENV['TWILIO_AUTH_TOKEN']
  end

  def call
    begin
      client = Twilio::REST::Client.new(@account_sid, @auth_token)
      message = client.messages.create(
        body: @body,
        to: @to,
        from: @from
      )
      Sublayer.configuration.logger.log(:info, "SMS sent successfully to {@to}")
      message.sid
    rescue Twilio::REST::TwilioError => e
      error_message = "Error sending SMS via Twilio: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end
