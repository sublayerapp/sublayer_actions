require 'httparty'

# Description: Sublayer::Action responsible for making generic HTTP requests.
# It supports GET, POST, PUT, and DELETE methods with customizable headers and body.
# This action is useful for interacting with various REST APIs.
#
# It is initialized with a URL, HTTP method (get, post, put, delete), optional headers, and an optional body.
# It returns the parsed response body as a Hash.
#
# Example usage: When you want to interact with a REST API to retrieve or send data.

class WebRequestAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(url:, method:, headers: {}, body: {})
    @url = url
    @method = method.downcase.to_sym
    @headers = headers
    @body = body
  end

  def call
    begin
      response = self.class.send(@method, @url, headers: @headers, body: @body)

      if response.success?
        Sublayer.configuration.logger.log(:info, "Successfully made #{@method.upcase} request to #{@url}")
        response.parsed_response
      else
        error_message = "Failed to make #{@method.upcase} request to #{@url}: HTTP #{response.code} - #{response.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue HTTParty::Error => e
      error_message = "HTTP error during #{@method.upcase} request: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during #{@method.upcase} request: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end