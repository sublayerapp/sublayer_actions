require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for sending HTTP POST webhook requests to arbitrary endpoints.
# This action enables integration with any service that accepts webhooks by allowing customizable
# payload delivery to specified URLs.
#
# It is initialized with a webhook_url and payload, with optional headers and timeout settings.
# It returns the HTTP response code to confirm successful webhook delivery.
#
# Example usage: When you want to trigger webhooks based on AI-generated insights or integrate
# with external services that support webhook notifications.

class WebhookTriggerAction < Sublayer::Actions::Base
  def initialize(webhook_url:, payload:, headers: {}, timeout: 30)
    @webhook_url = webhook_url
    @payload = payload
    @headers = {
      'Content-Type' => 'application/json',
      'User-Agent' => 'Sublayer-Webhook-Action'
    }.merge(headers)
    @timeout = timeout
  end

  def call
    send_webhook
  rescue URI::InvalidURIError => e
    error_message = "Invalid webhook URL: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue Net::ReadTimeout => e
    error_message = "Webhook request timed out after #{@timeout} seconds"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error sending webhook: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def send_webhook
    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    
    # Configure HTTP client
    http.use_ssl = (uri.scheme == 'https')
    http.read_timeout = @timeout
    http.open_timeout = @timeout

    # Prepare and send request
    request = Net::HTTP::Post.new(uri.request_uri)
    @headers.each { |key, value| request[key] = value }
    request.body = @payload.is_a?(String) ? @payload : @payload.to_json

    response = http.request(request)
    
    case response.code.to_i
    when 200..299
      Sublayer.configuration.logger.log(:info, "Webhook sent successfully to #{@webhook_url}")
      response.code.to_i
    else
      error_message = "Webhook request failed with status #{response.code}: #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end