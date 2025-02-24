require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for triggering webhooks with custom payloads.
# This action allows for integration with a wide variety of services that support webhook notifications.
#
# It is initialized with a webhook_url, payload (as a hash), and optional headers.
# It returns the HTTP response code to confirm the webhook was triggered successfully.
#
# Example usage: When you want to send data from an AI process to any service that supports webhook integrations.

class WebhookTriggerAction < Sublayer::Actions::Base
  def initialize(webhook_url:, payload:, headers: {})
    @webhook_url = webhook_url
    @payload = payload
    @headers = headers
  end

  def call
    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/json'
    @headers.each { |key, value| request[key] = value }
    request.body = @payload.to_json

    begin
      response = http.request(request)
      case response.code.to_i
      when 200..299
        Sublayer.configuration.logger.log(:info, "Webhook triggered successfully. Response code: #{response.code}")
        response.code.to_i
      else
        error_message = "Failed to trigger webhook. HTTP Response Code: #{response.code}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      error_message = "Error triggering webhook: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end
