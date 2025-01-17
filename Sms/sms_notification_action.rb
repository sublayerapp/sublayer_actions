require 'twilio-ruby'

# Description: Sublayer::Action responsible for sending an SMS notification using Twilio API.
# This action is useful for alerting users about important events or updates.
#
# Requires: 'twilio-ruby' gem
# $ gem install twilio-ruby
# Or add `gem 'twilio-ruby'` to your Gemfile
#
# It is initialized with a phone number and a message.
# It returns the SID of the sent message to confirm it was sent successfully.
#
# Example usage: When you want to send an alert or update from an AI process to a user's phone via SMS.

class SmsNotificationAction < Sublayer::Actions::Base
  def initialize(account_sid:, auth_token:, from_number:, to_number:, message:)
    @account_sid = account_sid
    @auth_token = auth_token
    @from_number = from_number
    @to_number = to_number
    @message = message
    @client = Twilio::REST::Client.new(@account_sid, @auth_token)
  end

  def call
    begin
      response = send_sms
      Sublayer.configuration.logger.log(:info, "SMS sent successfully to \\#{@to_number}")
      response.sid
    rescue Twilio::REST::TwilioError => e
      Sublayer.configuration.logger.log(:error, "Error sending SMS: \\#{e.message}")
      raise e
    end
  end

  private

  def send_sms
    @client.messages.create(
      from: @from_number,
      to: @to_number,
      body: @message
    )
  end
end
