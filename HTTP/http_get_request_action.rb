require 'httparty'

# Description: Sublayer::Action responsible for making an HTTP GET request to a specified URL.
# This action can be used to retrieve data from external APIs or web resources and incorporate it into Sublayer workflows.
#
# It is initialized with a URL and optional headers.
# It returns the body of the HTTP response as a string.
#
# Example usage: When you want to fetch data from a REST API to use in an LLM prompt or to trigger another action based on the API response.

class HttpGetRequestAction < Sublayer::Actions::Base
  include HTTParty
  format :plain # or :json, :xml, depending on the expected response type

  def initialize(url:, headers: {})
    @url = url
    @headers = headers
  end

  def call
    begin
      response = self.class.get(@url, headers: @headers)

      if response.success?
        Sublayer.configuration.logger.log(:info, "Successfully retrieved data from \#{@url}")
        response.body
      else
        error_message = "HTTP GET request failed: HTTP \#{response.code} - \#{response.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue HTTParty::Error => e
      error_message = "HTTParty error: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during HTTP GET request: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end