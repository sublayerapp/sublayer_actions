require 'httparty'

# Description: Sublayer::Action responsible for making an HTTP request to a specified endpoint.
# It uses HTTParty to handle the request and returns the parsed JSON response.
#
# This action can be used to integrate with various RESTful APIs and services.
#
# It is initialized with a url, optional method (default is GET), headers, and body.
# It returns the parsed JSON response from the API.
#
# Example usage: When you want to fetch data from an external API and use it in your Sublayer workflow.

class HTTPRequestAction < Sublayer::Actions::Base
  def initialize(url:, method: :get, headers: {}, body: {})
    @url = url
    @method = method.to_sym # Ensure method is a symbol
    @headers = headers
    @body = body
  end

  def call
    begin
      response = make_request
      Sublayer.configuration.logger.log(:info, "Successfully made HTTP request to \#{@url}")
      response.parsed_response
    rescue HTTParty::Error => e
      error_message = "HTTParty error: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error making HTTP request: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def make_request
    options = {}
    options[:headers] = @headers unless @headers.empty?
    options[:body] = @body unless @body.empty?

    case @method
    when :get
      HTTParty.get(@url, options)
    when :post
      HTTParty.post(@url, options)
    when :put
      HTTParty.put(@url, options)
    when :patch
      HTTParty.patch(@url, options)
    when :delete
      HTTParty.delete(@url, options)
    else
      raise StandardError, "Unsupported HTTP method: \#{@method}"
    end
  end
end