require 'httparty'

# Description: Sublayer::Action responsible for making a generic HTTP request.
# It supports various HTTP methods, headers, and request bodies, providing a versatile way to interact with REST APIs.
#
# It is initialized with a URL, HTTP method, headers, and body.
# It returns the parsed response body (JSON or text) and raises an error if the request fails.
#
# Example usage: When you need to interact with a REST API that doesn't have a dedicated action yet, or for more general API interactions.

class GenericHttpRequestAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(url:, method: 'get', headers: {}, body: {})
    @url = url
    @method = method.downcase.to_sym
    @headers = headers
    @body = body
  end

  def call
    make_request
  rescue HTTParty::Error => e
    error_message = "HTTP error during request: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error making HTTP request: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def make_request
    options = {
      headers: @headers,
    }
    options[:body] = @body.to_json unless @body.empty?

    response = HTTParty.send(@method, @url, options)

    if response.success?
      Sublayer.configuration.logger.log(:info, "HTTP request to #{@url} successful")
      begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        response.body
      end
    else
      error_message = "HTTP request failed: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end