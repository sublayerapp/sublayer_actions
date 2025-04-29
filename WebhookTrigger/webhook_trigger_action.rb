require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for triggering external webhooks with custom payloads.
# This action allows Sublayer to integrate with a wide variety of services that support webhook integrations.
#
# It is initialized with a webhook URL, payload, and optional HTTP method and headers.
# It returns the HTTP response code to confirm the webhook was triggered successfully.
#
# Example usage: When you want to send data or trigger an action in an external service based on AI-generated insights or automated processes.

class WebhookTriggerAction < Sublayer::Actions::Base
  def initialize(webhook_url:, payload:, method: :post, headers: {})
    @webhook_url = webhook_url
    @payload = payload
    @method = method.to_sym
    @headers = headers
  end

  def call
    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    request = create_request(uri)
    set_headers(request)
    request.body = @payload.to_json

    begin
      response = http.request(request)
      log_response(response)
      response.code.to_i
    rescue StandardError => e
      error_message = "Error triggering webhook: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_request(uri)
    case @method
    when :get
      Net::HTTP::Get.new(uri.request_uri)
    when :post
      Net::HTTP::Post.new(uri.request_uri)
    when :put
      Net::HTTP::Put.new(uri.request_uri)
    when :patch
      Net::HTTP::Patch.new(uri.request_uri)
    when :delete
      Net::HTTP::Delete.new(uri.request_uri)
    else
      raise ArgumentError, "Unsupported HTTP method: #{@method}"
    end
  end

  def set_headers(request)
    request.content_type = 'application/json'
    @headers.each { |key, value| request[key] = value }
  end

  def log_response(response)
    case response.code.to_i
    when 200..299
      Sublayer.configuration.logger.log(:info, "Webhook triggered successfully. Response code: #{response.code}")
    else
      Sublayer.configuration.logger.log(:warn, "Webhook trigger returned non-success status. Response code: #{response.code}")
    end
  end
end