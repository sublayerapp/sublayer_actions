require 'net/http'
require 'uri'

# Description: Sublayer::Action responsible for retrieving the content of a webpage.
# It fetches the HTML content from a given URL.
#
# It is initialized with a webpage_url.
# It returns the HTML content of the webpage as a string.
#
# Example usage: When you want to analyze the content of a webpage in your Sublayer workflow.

class GetWebpageContentAction < Sublayer::Actions::Base
  def initialize(webpage_url:)
    @webpage_url = webpage_url
  end

  def call
    begin
      uri = URI.parse(@webpage_url)
      response = Net::HTTP.get_response(uri)

      case response
      when Net::HTTPSuccess then
        Sublayer.configuration.logger.log(:info, "Successfully retrieved content from \#{@webpage_url}")
        response.body
      else
        error_message = "Failed to retrieve content from \#{@webpage_url}. HTTP Response Code: #{response.code}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue URI::InvalidURIError => e
      error_message = "Invalid URL: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue SocketError => e
      error_message = "Error connecting to \#{@webpage_url}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error retrieving webpage content: #{e.message}")
      raise e
    end
  end
end