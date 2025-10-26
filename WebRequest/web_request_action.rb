require 'httparty'
require 'json'

# Description: Sublayer::Action responsible for making an arbitrary web request and returning either the entire response body or an attribute of the response body defined with JSON path.
#
# It is initialized with a url, method (get, post, etc.), optional body (for post, put, patch), and an optional json_path to extract a specific value from the JSON response.
#
# Example usage: When you want to retrieve data from an API, submit data to a webhook, or generally interact with web services.

class WebRequestAction < Sublayer::Actions::Base
  def initialize(url:, method: 'get', body: nil, json_path: nil)
    @url = url
    @method = method.downcase.to_sym # Ensure method is a symbol and lowercase
    @body = body
    @json_path = json_path
  end

  def call
    begin
      response = make_request
      parsed_response = parse_response(response.body)

      result = @json_path ? extract_from_json(parsed_response, @json_path) : parsed_response

      Sublayer.configuration.logger.log(:info, "Successfully made web request to #{@url}")
      result

    rescue HTTParty::Error => e
      error_message = "HTTP error during web request: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue JSON::ParserError => e
      error_message = "Error parsing JSON response: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during web request: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def make_request
    options = {}
    options[:body] = @body.to_json if @body && @method != :get # Only include body for non-GET requests
    options[:headers] = { 'Content-Type' => 'application/json' } if @body # Set content type if body is present

    HTTParty.send(@method, @url, options)
  end

  def parse_response(body)
    JSON.parse(body)
  rescue JSON::ParserError
    # If not JSON, return the raw body
    body
  end

  def extract_from_json(parsed_response, json_path)
    keys = json_path.split('.')
    value = parsed_response

    keys.each do |key|
      if value.is_a?(Hash) && value.key?(key)
        value = value[key]
      elsif value.is_a?(Array) && key =~ /^\d+$/ # Check if key is an array index
        index = key.to_i
        value = value[index] if index < value.length
      else
        raise StandardError, "Invalid JSON path: #{json_path}"
      end
    end

    value
  end
end