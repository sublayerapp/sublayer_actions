# Description: Sublayer::Action for sending a message to a Discord webhook URL.
# This action can be used for sending formatted messages returned from an LLM to a specified Discord channel.
#
# Requires: `httparty` gem
# $ gem install httparty
# Or
# add `gem "httparty"` to your Gemfile
# and add `require "httparty"` somewhere in your app.

require 'httparty'

class DiscordSendMessageAction < Sublayer::Actions::Base
  def initialize(webhook_url:, message:)
    @webhook_url = webhook_url
    @message = message
  end

  def call
    begin
      response = HTTParty.post(
        @webhook_url,
        headers: { 'Content-Type' => 'application/json' },
        body: { content: @message }.to_json
      )
      if response.success?
        Sublayer.configuration.logger.log(:info, "Message sent successfully to Discord webhook.")
      else
        Sublayer.configuration.logger.log(
          :error,
          "Failed to send message to Discord webhook: "+
          "Status "+response.code.to_s+": "+response.message
        )
        raise "Failed to send message to Discord"
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error occurred while sending message to Discord: #{e.message}")
      raise e
    end
  end
end
