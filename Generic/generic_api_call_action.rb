require 'httparty'
require 'json'

# Description: Sublayer::Action responsible for making a generic API call to a REST endpoint.
# It takes in a URL, method (GET, POST, PUT, DELETE), headers, and body.
# It returns the JSON body of the response.
#
# Example usage: When you need to integrate with a service that doesn't have a dedicated action yet,
# or when the API call is highly dynamic and requires flexible configuration.

class GenericApiCallAction < Sublayer::Actions::Base
  include HTTParty

  def initialize(url:, method:, headers: {}, body: {})
    @url = url
    @method = method.upcase # Ensure method is uppercase
    @headers = headers
    @body = body.is_a?(String) ? body : body.to_json # Ensure body is JSON string
    @options = {
      headers: @headers
    }
    @options[:body] = @body unless @body.empty?
  end

  def call
    begin
      response = perform_request
      # Attempt to parse the response body as JSON
      begin
        parsed_response = JSON.parse(response.body)
      rescue JSON::ParserError
        # If parsing fails, return the raw response body as a string
        parsed_response = response.body
      end

      if response.success?
        Sublayer.configuration.logger.log(:info, "API call to \#{@url} successful")
        parsed_response
      else
        error_message = "API call to \#{@url} failed with HTTP \#{response.code}: \#{response.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue HTTParty::Error => e
      error_message = "HTTP error during API call: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during API call: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def perform_request
    case @method
    when 'GET'
      self.class.get(@url, @options)
    when 'POST'
      self.class.post(@url, @options)
    when 'PUT'
      self.class.put(@url, @options)
    when 'PATCH'
        self.class.patch(@url, @options)
    when 'DELETE'
      self.class.delete(@url, @options)
    else
      raise ArgumentError, "Unsupported HTTP method: \#{@method}"
    end
  end
end