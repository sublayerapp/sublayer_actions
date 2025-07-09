require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for making HTTP requests to webhook endpoints.
# This action provides a generic way to trigger webhooks with custom configurations.
#
# It is initialized with a webhook_url and supports various HTTP methods (GET/POST/PUT/DELETE),
# custom headers, and request body. It returns the response from the webhook endpoint.
#
# Example usage: When you want to integrate with any third-party service that accepts webhooks,
# or when you want to trigger automated actions in external systems based on AI-generated insights.

class WebhookTriggerAction < Sublayer::Actions::Base
  VALID_METHODS = %w[GET POST PUT DELETE].freeze

  def initialize(webhook_url:, method: 'POST', headers: {}, body: nil)
    @webhook_url = webhook_url
    @method = method.upcase
    @headers = headers
    @body = body

    validate_inputs
  end

  def call
    begin
      response = send_request
      handle_response(response)
    rescue URI::InvalidURIError => e
      error_message = "Invalid webhook URL: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue SocketError => e
      error_message = "Network error while triggering webhook: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error triggering webhook: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def validate_inputs
    unless VALID_METHODS.include?(@method)
      raise ArgumentError, "Invalid HTTP method: #{@method}. Must be one of: #{VALID_METHODS.join(', ')}"
    end

    URI.parse(@webhook_url) # Validates URL format
  end

  def send_request
    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    request = create_request(uri)
    setup_request(request)

    Sublayer.configuration.logger.log(:info, "Sending #{@method} request to #{@webhook_url}")
    http.request(request)
  end

  def create_request(uri)
    case @method
    when 'GET'
      Net::HTTP::Get.new(uri.request_uri)
    when 'POST'
      Net::HTTP::Post.new(uri.request_uri)
    when 'PUT'
      Net::HTTP::Put.new(uri.request_uri)
    when 'DELETE'
      Net::HTTP::Delete.new(uri.request_uri)
    end
  end

  def setup_request(request)
    # Set default headers
    request['Content-Type'] ||= 'application/json'
    request['Accept'] ||= 'application/json'

    # Add custom headers
    @headers.each do |key, value|
      request[key] = value
    end

    # Add body for non-GET requests
    if @body && @method != 'GET'
      request.body = @body.is_a?(String) ? @body : @body.to_json
    end
  end

  def handle_response(response)
    case response
    when Net::HTTPSuccess
      Sublayer.configuration.logger.log(:info, "Webhook triggered successfully")
      parse_response(response)
    else
      error_message = "Webhook request failed with status #{response.code}: #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  def parse_response(response)
    return response.body if response.body.empty?

    begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      response.body
    end
  end
end