require 'net/http'
require 'uri'

# Description: Sublayer::Action responsible for retrieving the content of a webpage via HTTP GET.
# This action is useful for scraping data, summarizing content, or feeding information into a generator.
#
# It is initialized with a URL.
# It returns the body of the HTTP response as a string.
#
# Example usage: When you want to fetch the HTML content of a webpage for analysis or processing.

class HTTPGetAction < Sublayer::Actions::Base
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
        Sublayer.configuration.logger.log(:info, "Successfully retrieved content from \#{@url}")
        response.body
      else
        error_message = "Failed to retrieve content from \#{@url}. HTTP Response Code: #{response.code}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error retrieving content from \#{@url}: #{e.message}")
      raise e
    end
  end
end
