require 'net/http'
require 'uri'

# Description: Sublayer::Action responsible for retrieving the content of a webpage given a URL.
# This action uses Net::HTTP to fetch the HTML content from the specified URL.
#
# It is initialized with a url parameter.
# It returns the HTML content of the webpage as a string.
#
# Example usage: When you need to provide context from a webpage to a Sublayer::Generator, such as
# summarizing an article or extracting specific information.

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
    rescue SocketError => e
      error_message = "Error connecting to \#{@url}: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error retrieving webpage content: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end