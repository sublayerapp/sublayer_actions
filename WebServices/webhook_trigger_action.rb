require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for triggering custom webhooks.
# This action allows Sublayer workflows to integrate with a wide variety of external services
# and systems that support webhook integrations.
#
# It is initialized with a webhook_url, http_method, and optional headers and payload.
# It returns the HTTP response code to confirm the webhook was triggered successfully.
#
# Example usage: When you want to notify or update an external system based on the results of an AI-driven process.

class WebhookTriggerAction < Sublayer::Actions::Base
  def initialize(webhook_url:, http_method: :post, headers: {}, payload: nil)
    @webhook_url = webhook_url
    @http_method = http_method.to_sym
    @headers = headers
    @payload = payload
  end

  def call
    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    request = create_request(uri)
    set_headers(request)
    set_payload(request) if @payload

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
    case @http_method
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
      raise ArgumentError, "Unsupported HTTP method: #{@http_method}"
    end
  end

  def set_headers(request)
    @headers.each do |key, value|
      request[key] = value
    end
    request['Content-Type'] = 'application/json' if @payload
  end

  def set_payload(request)
    request.body = @payload.is_a?(String) ? @payload : @payload.to_json
  end

  def log_response(response)
    if response.code.to_i.between?(200, 299)
      Sublayer.configuration.logger.log(:info, "Webhook triggered successfully. Response code: #{response.code}")
    else
      Sublayer.configuration.logger.log(:warn, "Webhook trigger returned non-success status. Response code: #{response.code}")
    end
  end
end