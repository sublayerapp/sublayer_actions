require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action for making generic HTTP requests.
# This action enables interaction with a wide range of web services and APIs.
#
# It is initialized with a url, method, headers, and body.
# It returns the HTTP response.
#
# Example usage: When you want to interact with any HTTP-based API or service.

class HttpRequestAction < Sublayer::Actions::Base
  def initialize(url:, method: 'GET', headers: {}, body: nil)
    @url = url
    @method = method.upcase
    @headers = headers
    @body = body
  end

  def call
    uri = URI.parse(@url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    request_class = Net::HTTP.const_get(@method)
    request = request_class.new(uri.request_uri)

    @headers.each do |key, value|
      request[key] = value
    end

    request.body = @body.to_json if @body && ['POST', 'PUT', 'PATCH'].include?(@method)

    begin
      response = http.request(request)
      Sublayer.configuration.logger.log(:info, "HTTP request sent successfully to #{@url}")
      response
    rescue Net::HTTPError => e
      error_message = "HTTP request failed: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end