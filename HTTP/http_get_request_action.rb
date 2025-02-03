# Description: Sublayer::Action responsible for making HTTP GET requests and returning the response.
# It can be utilized for interfacing with web APIs or external services to fetch data.
# This action is initialized with a URL and optional headers.
# It returns the body of the HTTP response.
# 
# Requires: standard 'net/http' and 'uri' libraries, which are part of the Ruby Standard Library.

require 'net/http'
require 'uri'
require 'json'

class HTTPGetRequestAction < Sublayer::Actions::Base
  def initialize(url:, headers: {})
    @url = url
    @headers = headers
  end

  def call
    uri = URI.parse(@url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    request = Net::HTTP::Get.new(uri.request_uri)
    @headers.each do |key, value|
      request[key] = value
    end

    begin
      response = http.request(request)
      case response.code.to_i
      when 200..299
        Sublayer.configuration.logger.log(:info, "HTTP GET request successful to #{@url}")
        response.body
      else
        error_message = "HTTP GET request failed to #{@url}. HTTP Response Code: #{response.code}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error making HTTP GET request: #{e.message}")
      raise e
    end
  end
end
