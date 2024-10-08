require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action that posts an image URL to a Discord channel using a webhook.
# This action is designed to work with the output of OpenAIImageGenerationAction,
# making it easy to share AI-generated images.
#
# It is initialized with a webhook_url and an image_url.
# It returns the HTTP response code to confirm the message was sent successfully.
#
# Example usage: When you want to share an AI-generated image to a Discord channel.

class OpenAIImageToDiscordAction < Sublayer::Actions::Base
  def initialize(webhook_url:, image_url:)
    @webhook_url = webhook_url
    @image_url = image_url
  end

  def call
    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/json'
    request.body = { content: "![](#{@image_url})"} .to_json

    begin
      response = http.request(request)
      case response.code.to_i
      when 200..299
        Sublayer.configuration.logger.log(:info, "Image sent successfully to Discord webhook")
        response.code.to_i
      else
        error_message = "Failed to send image to Discord. HTTP Response Code: #{response.code}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending image to Discord: #{e.message}")
      raise e
    end
  end
end