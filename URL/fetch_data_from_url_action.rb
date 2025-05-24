require 'httparty'
require 'json'

# Description: Sublayer::Action responsible for fetching data from a URL.
# It supports various content types (JSON, CSV, plain text) and can handle basic authentication.
#
# It is initialized with a url and optional parameters like headers (for authentication or content type).
# It returns the parsed data (e.g., a JSON object, CSV array, or plain text string).
#
# Example usage: When you want to fetch data from a REST API or a publicly available data source for use in a Sublayer::Generator.

class FetchDataFromURLAction < Sublayer::Actions::Base
  include HTTParty
  format :json # Default format

  def initialize(url:, headers: {})
    @url = url
    @headers = headers
  end

  def call
    begin
      response = self.class.get(@url, headers: @headers)

      unless response.success?
        error_message = "HTTP request failed: HTTP \#{response.code} - \#{response.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end

      content_type = response.headers['content-type']

      case content_type
      when /json/
        JSON.parse(response.body)
      when /csv/
        CSV.parse(response.body)
      when /text/
        response.body
      else
        response.body # Return as string if content type is not recognized
      end

    rescue HTTParty::Error => e
      error_message = "HTTP error fetching data from URL: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue JSON::ParserError => e
      error_message = "Error parsing JSON response: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue CSV::MalformedCSVError => e
       error_message = "Error parsing CSV response: \#{e.message}"
       Sublayer.configuration.logger.log(:error, error_message)
       raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error fetching data from URL: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end