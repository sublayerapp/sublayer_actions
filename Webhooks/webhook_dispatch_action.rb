require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for sending generic webhook POST requests.
# This action provides a flexible way to integrate with any service that accepts webhooks
# by allowing customizable headers and payload data.
#
# It is initialized with a webhook_url, optional headers, and a payload (which can be a hash or string).
# It returns the HTTP response code to confirm the webhook was sent successfully.
#
# Example usage: When you want to send AI-generated data to any external service that accepts webhooks,
# such as automation platforms, custom APIs, or integration services.

class WebhookDispatchAction < Sublayer::Actions::Base
  def initialize(webhook_url:, payload:, headers: {})
    @webhook_url = webhook_url
    @payload = payload
    @headers = {
      'Content-Type' => 'application/json',
      'User-Agent' => 'Sublayer-Webhook-Dispatch'
    }.merge(headers)
  end

  def call
    begin
      send_webhook
    rescue URI::InvalidURIError => e
      error_message = "Invalid webhook URL: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error dispatching webhook: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def send_webhook
    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    request = Net::HTTP::Post.new(uri.request_uri)
    @headers.each { |key, value| request[key] = value }
    
    # Convert payload to JSON if it's a Hash
    request.body = @payload.is_a?(Hash) ? @payload.to_json : @payload.to_s

    response = http.request(request)
    
    case response.code.to_i
    when 200..299
      Sublayer.configuration.logger.log(:info, "Webhook dispatched successfully to #{@webhook_url}")
      response.code.to_i
    else
      error_message = "Webhook request failed: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end