# Description: Sublayer::Action responsible for sending a formatted message to a Discord channel via webhook.
# It is intended to be a bridge between AI-generated content and Discord channels, ensuring messages are relayed promptly and accurately.
#
# Requires: `net/http` for HTTP requests. JSON to format message payloads.
# Ruby's standard library should cover this without additional gems.
#
# It is initialized with a webhook_url and a message content, and it optionally takes an array of embeds for rich message formatting.
# It returns a truthy value if the message was successfully sent.
#
# Example usage: When you want to post updates from AI processes to a Discord channel.

require 'net/http'
require 'json'

class DiscordSendMessageAction < Sublayer::Actions::Base
  def initialize(webhook_url:, content:, embeds: [])
    @webhook_url = webhook_url
    @content = content
    @embeds = embeds
  end

  def call
    uri = URI(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
    request.body = { content: @content, embeds: @embeds }.to_json
    
    response = http.request(request)
    
    if response.is_a?(Net::HTTPSuccess)
      Sublayer.configuration.logger.log(:info, "Message sent successfully to Discord")
      true
    else
      log_error(response)
      false
    end
  rescue StandardError => e
    Sublayer.configuration.logger.log(:error, "Error sending Discord message: #{e.message}")
    raise e
  end

  private

  def log_error(response)
    error_message = "Discord API Error: "+
                    "Status: #{response.code}, " +
                    "Body: #{response.body}"
    Sublayer.configuration.logger.log(:error, error_message)
  end
end
