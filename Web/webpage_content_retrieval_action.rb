require 'net/http'
require 'uri'

# Description: Sublayer::Action responsible for retrieving the content of a webpage given a URL.
# It uses the Net::HTTP library to make an HTTP GET request to the specified URL
# and returns the body of the response. It includes error handling for invalid URLs and HTTP errors.
#
# It is initialized with a url parameter.
# It returns the content of the webpage as a string.
#
# Example usage: When you want to scrape information from websites to use in prompts or analysis.

class WebpageContentRetrievalAction < Sublayer::Actions::Base
  def initialize(url:)
    @url = url
  end

  def call
    begin
      uri = URI.parse(@url)
      response = Net::HTTP.get_response(uri)

      case response
      when Net::HTTPSuccess
        Sublayer.configuration.logger.log(:info, "Successfully retrieved content from \#{@url}")
        response.body
      else
        error_message = "Failed to retrieve content from \#{@url}. HTTP Response Code: #{response.code}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue URI::InvalidURIError => e
      error_message = "Invalid URL: \#{@url}. Error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error retrieving webpage content: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end