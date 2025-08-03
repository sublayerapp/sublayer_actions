require 'httparty'
require 'json'

# Description: Sublayer::Action responsible for fetching structured data (JSON or YAML) from a given URL.
# This action uses HTTParty to make the request and parses the response body as JSON.
#
# It is initialized with a url and returns a Ruby hash representing the parsed data.
#
# Example usage: When you want to fetch real-time data from an API endpoint and use it in a Sublayer::Generator.
#
# Note: This action assumes the API returns JSON data.  It could be extended to support YAML as well.

class FetchStructuredDataAction < Sublayer::Actions::Base
  def initialize(url:)
    @url = url
  end

  def call
    begin
      response = HTTParty.get(@url)

      unless response.success?
        error_message = "HTTP request failed: \#{response.code} - \#{response.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end

      # Attempt to parse the response body as JSON
      begin
        parsed_data = JSON.parse(response.body)
        Sublayer.configuration.logger.log(:info, "Successfully fetched and parsed data from \#{@url}")
        return parsed_data
      rescue JSON::ParserError => e
        error_message = "Failed to parse JSON response: \#{e.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end

    rescue HTTParty::Error => e
      error_message = "HTTParty error: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error fetching structured data: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end