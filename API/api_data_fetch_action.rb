require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for fetching data from a specified API endpoint.
# This action enables the integration of external data sources into Sublayer workflows.
#
# It is initialized with an api_url and optional headers for authentication or other purposes.
# It returns the parsed JSON response.
#
# Example usage: When you want to collect data from an external API to include in a Sublayer process.

class APIDataFetchAction < Sublayer::Actions::Base
  def initialize(api_url:, headers: {})
    @api_url = api_url
    @headers = headers
  end

  def call
    fetch_data
  rescue StandardError => e
    error_message = "Error fetching data from API: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def fetch_data
    uri = URI.parse(@api_url)
    request = Net::HTTP::Get.new(uri)
    @headers.each { |key, value| request[key] = value }

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    case response
    when Net::HTTPSuccess
      JSON.parse(response.body)
    else
      error_message = "Failed to fetch data: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
