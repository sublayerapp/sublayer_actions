require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for triggering a webhook by sending a POST request to a specified URL.
# This action allows Sublayer to integrate with a wide variety of services that support webhook notifications.
#
# It is initialized with a webhook_url and an optional payload.
# It returns the HTTP response code to confirm the webhook was triggered successfully.
#
# Example usage: When you want to notify an external service about an event or update from your Sublayer workflow.

class WebhookTriggerAction < Sublayer::Actions::Base
  def initialize(webhook_url:, payload: {})
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
        Sublayer.configuration.logger.log(:info, "Webhook triggered successfully. URL: #{@webhook_url}")
        response.code.to_i
      else
        error_message = "Failed to trigger webhook. HTTP Response Code: #{response.code}. URL: #{@webhook_url}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error triggering webhook: #{e.message}. URL: #{@webhook_url}")
      raise e
    end
  end
end