# Description: Sublayer::Action responsible for sending a message to a Discord channel via a webhook URL.
# It can be used for notifications or updates from AI-driven processes.
#
# It is initialized with a webhook_url and a message.
# It logs the activity and raises an error if the message fails to send.
#
# Example usage: When you want to send a notification or a formatted message returned from an LLM to a Discord channel.

require 'net/http'
require 'uri'
require 'json'

class DiscordSendMessageAction < Sublayer::Actions::Base
  def initialize(webhook_url:, message:)
    @webhook_url = webhook_url
    @message = message
    @uri = URI.parse(@webhook_url)
  end

  def call
    begin
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(@uri.request_uri, {'Content-Type' => 'application/json'})
      request.body = {content: @message}.to_json

      response = http.request(request)

      if response.is_a?(Net::HTTPSuccess)
        Sublayer.configuration.logger.log(:info, "Message sent successfully to Discord webhook at #{@webhook_url}")
        return response.body
      else
        handle_error(response)
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending Discord message: #{e.message}")
      raise e
    end
  end

  private

  def handle_error(response)
    error_message = "Failed to send message to Discord. HTTP Status: #{response.code} #{response.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end
end
