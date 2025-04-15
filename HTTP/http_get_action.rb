require 'net/http'
require 'uri'

# Description: Sublayer::Action responsible for making an HTTP GET request to a specified URL and returning the content.
# This action is useful for fetching data from web services or APIs for use in Sublayer::Generators.
#
# It is initialized with a url.
# It returns the content of the response body as a string.
#
# Example usage: When you want to fetch data from a REST API and use it in a prompt.

class HttpGetAction < Sublayer::Actions::Base
  def initialize(url:)
    @url = url
  end

  def call
    uri = URI.parse(@url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    request = Net::HTTP::Get.new(uri.request_uri)

    begin
      response = http.request(request)

      case response
      when Net::HTTPSuccess
        Sublayer.configuration.logger.log(:info, "Successfully fetched content from \#{@url}")
        response.body
      else
        error_message = "HTTP GET request failed: \#{response.code} - \#{response.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error fetching URL: \#{e.message}")
      raise e
    end
  end
end