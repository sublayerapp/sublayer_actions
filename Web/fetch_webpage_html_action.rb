# Description: Sublayer::Action responsible for fetching the HTML content of a webpage.
# This action allows for scraping web pages for data to be used in prompts or other analysis.
#
# It is initialized with a URL.
# It returns the HTML content as a string.
#
# Example usage: When you want to scrape a webpage for data to be used in a prompt.

require 'net/http'
require 'uri'

class FetchWebpageHTMLAction < Sublayer::Actions::Base
  def initialize(url:)
    @url = url
  end

  def call
    begin
      uri = URI.parse(@url)
      response = Net::HTTP.get_response(uri)

      case response
      when Net::HTTPSuccess
        Sublayer.configuration.logger.log(:info, "Successfully fetched HTML from \#{@url}")
        response.body
      else
        error_message = "Failed to fetch HTML from \#{@url}. HTTP Response Code: #{response.code}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue URI::InvalidURIError => e
      error_message = "Invalid URL: \#{@url}. Error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error fetching HTML from \#{@url}. Error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end