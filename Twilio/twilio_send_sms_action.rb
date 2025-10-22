require 'twilio-ruby'

# Description: Sublayer::Action responsible for sending SMS messages using the Twilio API.
# This action can be used for sending alerts or notifications as part of AI-driven workflows.
#
# It is initialized with a phone number to send the message to, the message content, and optional media_url.
# It returns a confirmation message SID upon successful sending of the SMS.
#
# Example usage: When you want to send a notification to a user's phone number as part of an AI process.

class TwilioSendSmsAction < Sublayer::Actions::Base
  def initialize(to:, body:, media_url: nil)
    @to = to
    @body = body
    @media_url = media_url
    @account_sid = ENV['TWILIO_ACCOUNT_SID']
    @auth_token = ENV['TWILIO_AUTH_TOKEN']
    @from_number = ENV['TWILIO_PHONE_NUMBER']
    @client = Twilio::REST::Client.new(@account_sid, @auth_token)
  end

  def call
    begin
      message = send_sms
      Sublayer.configuration.logger.log(:info, "SMS sent successfully with SID: #{message.sid}")
      message.sid
    rescue Twilio::REST::TwilioError => e
      error_message = "Error sending SMS: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def send_sms
    options = { from: @from_number, to: @to, body: @body }
    options[:media_url] = @media_url if @media_url
    @client.messages.create(options)
  end
end
