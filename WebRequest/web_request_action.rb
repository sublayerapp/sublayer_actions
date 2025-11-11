require 'httparty'

# Description: Sublayer::Action responsible for making an HTTP request to a specified URL.
# It supports GET, POST, PUT, and DELETE methods, and allows setting custom headers and request bodies.
# It returns the response body as a string.
#
# It is initialized with a url, method (GET, POST, PUT, DELETE), headers (optional), and body (optional).
#
# Example usage: When you need to fetch data from an external API, send data to a webhook, or interact with web services.

class WebRequestAction < Sublayer::Actions::Base
  include HTTParty

  def initialize(url:, method:, headers: {}, body: nil)
    @url = url
    @method = method.upcase # Ensure method is uppercase for consistency
    @headers = headers
    @body = body
  end

  def call
    begin
      response = make_request
      Sublayer.configuration.logger.log(:info, "Successfully made a \#{@method} request to \#{@url}")
      response.body
    rescue HTTParty::Error => e
      error_message = "HTTParty error during web request: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error making web request: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def make_request
    case @method
    when 'GET'
      self.class.get(@url, headers: @headers)
    when 'POST'
      self.class.post(@url, headers: @headers, body: @body)
    when 'PUT'
      self.class.put(@url, headers: @headers, body: @body)
    when 'DELETE'
      self.class.delete(@url, headers: @headers, body: @body)
    else
      raise ArgumentError, "Unsupported HTTP method: #{@method}"
    end
  end
end