require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for fetching data from a given URL using an HTTP GET request.
# It returns the response body in the desired format (default: JSON, can be 'text').
#
# Example usage: When you need to integrate data from an external API into your Sublayer workflow.

class HTTPGetDataAction < Sublayer::Actions::Base
  def initialize(url:, format: 'json')
    @url = url
    @format = format.downcase
  end

  def call
    begin
      uri = URI.parse(@url)
      response = Net::HTTP.get_response(uri)

      case response
      when Net::HTTPSuccess
        process_response(response.body)
      else
        error_message = "HTTP Request failed (\#{response.code}): \#{response.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error fetching data from \#{@url}: \#{e.message}")
      raise e
    end
  end

  private

  def process_response(body)
    case @format
    when 'json'
      JSON.parse(body)
    when 'text'
      body
    else
      raise ArgumentError, "Invalid format specified: \#{@format}. Valid formats are 'json' and 'text'."
    end
  end
end