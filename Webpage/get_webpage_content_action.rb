require 'httparty'

# Description: Sublayer::Action responsible for retrieving the content of a webpage given a URL.
# It uses HTTParty to fetch the HTML content and returns it as a string.
# Useful for web scraping tasks or when you need to summarize content from a live webpage.
#
# It is initialized with a url.
# It returns the HTML content of the webpage as a string.
#
# Example usage: When you want to summarize the content of a webpage or extract specific information from it.

class GetWebpageContentAction < Sublayer::Actions::Base
  include HTTParty
  format :html

  def initialize(url:)
    @url = url
  end

  def call
    begin
      response = self.class.get(@url)

      if response.success?
        Sublayer.configuration.logger.log(:info, "Successfully retrieved content from \#{@url}")
        response.body
      else
        error_message = "Failed to retrieve content from \#{@url}. HTTP Response Code: #{response.code}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue HTTParty::Error => e
      error_message = "HTTP error while retrieving content from \#{@url}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error retrieving content from \#{@url}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end