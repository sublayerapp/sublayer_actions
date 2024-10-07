require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for sending a rich embed message to a Discord webhook.
# This action extends the functionality of DiscordSendMessageAction by allowing more visually appealing
# and structured messages, which can be particularly useful for presenting AI-generated content or reports.
#
# It is initialized with a webhook_url and embed data (which follows Discord's embed structure).
# It returns the HTTP response code to confirm the message was sent successfully.
#
# Example usage: When you want to send a structured, visually appealing message or report from an AI process to a Discord channel.

class DiscordEmbedMessageAction < Sublayer::Actions::Base
  def initialize(webhook_url:, embed:)
    @webhook_url = webhook_url
    @embed = embed
  end

  def call
    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/json'
    request.body = { embeds: [@embed] }.to_json

    begin
      response = http.request(request)
      case response.code.to_i
      when 200..299
        Sublayer.configuration.logger.log(:info, 'Embed message sent successfully to Discord webhook')
        response.code.to_i
      else
        error_message = "Failed to send embed message to Discord. HTTP Response Code: #{response.code}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending Discord embed message: #{e.message}")
      raise e
    end
  end
end
