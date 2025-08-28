require 'twilio-ruby'

# Description: Sublayer::Action responsible for sending SMS messages via Twilio.
# This action enables AI agents to send notifications or alerts via SMS, particularly useful
# for urgent communications or time-sensitive updates.
#
# Requires: 'twilio-ruby' gem
# $ gem install twilio-ruby
# Or add `gem 'twilio-ruby'` to your Gemfile
#
# It is initialized with a to_phone_number and message content.
# Optionally, a from_phone_number can be specified; otherwise uses the default Twilio number from env.
# It returns the Twilio message SID on successful sending.
#
# Example usage: When an AI agent needs to send urgent notifications or updates to stakeholders via SMS.

class TwilioSendSmsAction < Sublayer::Actions::Base
  def initialize(to_phone_number:, message:, from_phone_number: nil)
    @to_phone_number = to_phone_number
    @message = message
    @from_phone_number = from_phone_number || ENV['TWILIO_PHONE_NUMBER']
    @account_sid = ENV['TWILIO_ACCOUNT_SID']
    @auth_token = ENV['TWILIO_AUTH_TOKEN']
  end

  def call
    begin
      validate_phone_numbers
      client = Twilio::REST::Client.new(@account_sid, @auth_token)
      
      response = client.messages.create(
        from: @from_phone_number,
        to: @to_phone_number,
        body: @message
      )

      Sublayer.configuration.logger.log(:info, "SMS sent successfully to #{@to_phone_number}. Message SID: #{response.sid}")
      response.sid
    rescue Twilio::REST::RestError => e
      error_message = "Twilio API error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error sending SMS: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def validate_phone_numbers
    unless valid_phone_number?(@to_phone_number) && valid_phone_number?(@from_phone_number)
      raise StandardError, "Invalid phone number format. Numbers should be in E.164 format (e.g., +1234567890)"
    end
  end

  def valid_phone_number?(number)
    # Basic E.164 format validation
    number.match?(/^\+[1-9]\d{1,14}$/)
  end
end