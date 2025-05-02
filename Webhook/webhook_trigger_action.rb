require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for sending an HTTP POST request to a specified webhook URL with a JSON payload.
# This action allows easy integration with various third-party services that support webhooks,
# enabling notifications or triggering of external processes.
#
# It is initialized with a webhook_url and a payload (as a Ruby hash).
# It returns the HTTP response code to confirm the webhook was triggered successfully.
#
# Example usage: When you want to notify or trigger an external service based on the result of an AI-driven process.

class WebhookTriggerAction < Sublayer::Actions::Base
  def initialize(webhook_url:, payload:)
    @webhook_url = webhook_url
    @payload = payload
  end

  def call
    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/json'
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