require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for making an HTTP GET request to a specified URL and returning the response body.
# This action allows integration with REST APIs or any web resource that provides data via HTTP GET.
#
# It is initialized with a URL.  It can optionally take headers as a hash.
# It returns the response body as a string.
#
# Example usage: When you need to fetch data from an external API to use in a Sublayer::Generator prompt or other AI workflow.

class HttpGetAction < Sublayer::Actions::Base
  def initialize(url:, headers: {})
    @url = url
    @headers = headers
  end

  def call
    uri = URI.parse(@url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    request = Net::HTTP::Get.new(uri.request_uri, @headers)

    begin
      response = http.request(request)

      case response
      when Net::HTTPSuccess
        Sublayer.configuration.logger.log(:info, "Successfully retrieved data from \#{@url}")
        response.body
      else
        error_message = "HTTP GET request failed: \#{response.code} \#{response.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error during HTTP GET request: \#{e.message}")
      raise e
    end
  end
end