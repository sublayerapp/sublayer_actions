require 'httparty'

# Description: Sublayer::Action responsible for retrieving the content of a webpage given a URL.
# It uses HTTParty to fetch the HTML content, which can then be used as input for a Generator
# to summarize the page or extract specific information.
#
# It is initialized with a url.
# It returns the body of the response from the URL as a string.
#
# Example usage: When you want to summarize the content of a webpage or extract information from it.

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
        error_message = "Failed to retrieve content from \#{@url}: HTTP \#{response.code} - \#{response.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue HTTParty::Error => e
      error_message = "HTTP error during content retrieval: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error retrieving webpage content: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end