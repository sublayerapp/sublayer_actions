require 'httparty'

# Description: Sublayer::Action responsible for making a generic REST API call.
# It uses the HTTParty gem to handle HTTP requests and supports configurable
# HTTP methods (GET, POST, PUT, PATCH, DELETE), headers, and request bodies.
#
# It is initialized with a URL, HTTP method, optional headers, and an optional request body.
# It returns the parsed response body as a Ruby object (e.g., Hash, Array).
#
# Example usage: When you need to interact with a RESTful API for which a dedicated
# Sublayer::Action does not yet exist, or when you need a highly configurable API interaction.

class RestApiCallAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(url:, method:, headers: {}, body: nil)
    @url = url
    @method = method.to_s.downcase.to_sym # Ensure method is a symbol and lowercase
    @headers = headers
    @body = body
  end

  def call
    make_api_call
  rescue HTTParty::Error => e
    error_message = "HTTP error during API call: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error during REST API call: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def make_api_call
    options = { headers: @headers }
    options[:body] = @body.to_json if @body # Convert body to JSON if present

    response = case @method
               when :get
                 self.class.get(@url, options)
               when :post
                 self.class.post(@url, options)
               when :put
                 self.class.put(@url, options)
               when :patch
                 self.class.patch(@url, options)
               when :delete
                 self.class.delete(@url, options)
               else
                 raise ArgumentError, "Unsupported HTTP method: #{@method}"
               end

    if response.success?
      parsed_response = response.parsed_response
      Sublayer.configuration.logger.log(:info, "API call to #{@url} successful")
      parsed_response
    else
      error_message = "API call to #{@url} failed: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end