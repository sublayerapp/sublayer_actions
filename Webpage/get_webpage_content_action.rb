require 'net/http'
require 'uri'

# Description: Sublayer::Action responsible for retrieving the text content of a webpage given a URL.
# This action is useful for providing context to LLMs from online sources.
#
# It is initialized with a url and returns the text content of the webpage.
#
# Example usage: When you want to provide context to LLMs from online sources.

class GetWebpageContentAction < Sublayer::Actions::Base
  def initialize(url:)
    @url = url
  end

  def call
    begin
      uri = URI.parse(@url)
      response = Net::HTTP.get_response(uri)

      case response
      when Net::HTTPSuccess then
        Sublayer.configuration.logger.log(:info, "Successfully retrieved content from \#{@url}")
        response.body
      else
        error_message = "Failed to retrieve content from \#{@url}: HTTP \#{response.code} \#{response.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue URI::InvalidURIError => e
      error_message = "Invalid URL: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error retrieving webpage content: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end