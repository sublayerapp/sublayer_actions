require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for sending a formatted message to a Discord webhook.
# This action is intended to be used for sending LLM-generated messages to a Discord channel.
#
# It is initialized with a webhook_url and a message (which can be formatted as per Discord's message formatting).
# It returns the HTTP response code to confirm the message was sent successfully.
#
# Example usage: When you want to send a notification or update from an AI process to a Discord channel.

class DiscordSendMessageAction < Sublayer::Actions::Base
  def initialize(webhook_url:, message:)
    @webhook_url = webhook_url
    @message = message
  end

  def call
    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/json'
    request.body = { content: @message }.to_json

    begin
      response = http.request(request)
      case response.code.to_i
      when 200..299
        Sublayer.configuration.logger.info("Message sent successfully to Discord webhook")
        response.code.to_i
      else
        error_message = "Failed to send message to Discord. HTTP Response Code: #{response.code}"
        Sublayer.configuration.logger.error(error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.error("Error sending Discord message: #{e.message}")
      raise e
    end
  end
end