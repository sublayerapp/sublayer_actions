require 'net/http'
require 'uri'

# Description: Sublayer::Action responsible for retrieving the text content of a webpage given its URL.
# This action is useful for scraping data or providing context to a generator.
#
# It is initialized with a webpage URL.
# It returns the text content of the webpage.
#
# Example usage: When you want to fetch the content of a blog post for summarization or analysis.

class GetWebpageContentAction < Sublayer::Actions::Base
  def initialize(url:)
    @url = url
  end

  def call
    begin
      uri = URI.parse(@url)
      response = Net::HTTP.get_response(uri)

      case response
      when Net::HTTPSuccess
        text_content = response.body
        Sublayer.configuration.logger.log(:info, "Successfully retrieved content from \#{@url}")
        text_content
      else
        error_message = "Failed to retrieve content from \#{@url}. HTTP Response Code: #{response.code}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue URI::InvalidURIError => e
      error_message = "Invalid URL: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue SocketError => e
       error_message = "Error connecting to \#{@url}: \#{e.message}"
       Sublayer.configuration.logger.log(:error, error_message)
       raise StandardError, error_message
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error retrieving webpage content: \#{e.message}")
      raise e
    end
  end
end