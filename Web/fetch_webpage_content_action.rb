require 'net/http'
require 'uri'

# Description: Sublayer::Action responsible for fetching the HTML content of a webpage.
# This action takes a URL as input and returns the HTML content of the page.
#
# It is initialized with a url. It returns the HTML content of the webpage as a string.
#
# Example usage: When you want to scrape data from a webpage, summarize content, or check for updates.

class FetchWebpageContentAction < Sublayer::Actions::Base
  def initialize(url:)
    @url = url
  end

  def call
    begin
      uri = URI.parse(@url)
      response = Net::HTTP.get_response(uri)

      case response
      when Net::HTTPSuccess then
        Sublayer.configuration.logger.log(:info, "Successfully fetched content from \#{@url}")
        response.body
      else
        error_message = "Failed to fetch content from \#{@url}. HTTP Response Code: #{response.code}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue URI::InvalidURIError => e
      error_message = "Invalid URL: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue SocketError => e
       error_message = "Invalid URL: #{e.message}"
       Sublayer.configuration.logger.log(:error, error_message)
       raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error fetching webpage content: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end