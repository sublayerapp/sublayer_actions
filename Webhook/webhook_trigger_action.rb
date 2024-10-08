require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action that sends an HTTP POST request with a customizable payload
# to a specified URL, allowing integration with any webhook API.
#
# Example usage: When you want to notify an external service via webhook with dynamically
# generated data.

class WebhookTriggerAction < Sublayer::Actions::Base
  def initialize(url:, payload:, headers: {})
    @url = url
    @payload = payload
    @headers = headers
  end

  def call
    uri = URI.parse(@url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/json'
    @headers.each { |key, value| request[key] = value }
    request.body = @payload.to_json

    begin
      response = http.request(request)
      handle_response(response)
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending webhook request: #{e.message}")
      raise e
    end
  end

  private

  def handle_response(response)
    case response.code.to_i
    when 200..299
      Sublayer.configuration.logger.log(:info, "Webhook triggered successfully. Response: #{response.body}")
    else
      error_message = "Failed to trigger webhook. HTTP Response Code: #{response.code}, Body: #{response.body}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
