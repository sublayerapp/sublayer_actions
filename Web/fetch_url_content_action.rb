require 'net/http'
require 'uri'
require 'json'
require 'nokogiri'

# Description: Sublayer::Action responsible for fetching content from a given URL.
# This action supports various content types including HTML, JSON, and XML.
#
# It is initialized with a URL and returns the content as a string.
# For JSON content, it parses the JSON and returns a Ruby hash.
# For XML content, it parses the XML and returns a Nokogiri::XML::Document.
# For other content types, it returns the raw content as a string.
#
# Example usage: When you want to scrape data from a website or consume a web API within your Sublayer workflow.

class FetchURLContentAction < Sublayer::Actions::Base
  def initialize(url:)
    @url = url
  end

  def call
    uri = URI.parse(@url)
    response = Net::HTTP.get_response(uri)

    case response
    when Net::HTTPSuccess
      content_type = response['Content-Type']
      body = response.body

      case content_type
      when /application\/json/
        begin
          JSON.parse(body)
        rescue JSON::ParserError => e
          error_message = "Error parsing JSON: #{e.message}"
          Sublayer.configuration.logger.log(:error, error_message)
          raise StandardError, error_message
        end
      when /application\/xml/, /text\/xml/
        begin
          Nokogiri::XML(body)
        rescue Nokogiri::XML::SyntaxError => e
          error_message = "Error parsing XML: #{e.message}"
          Sublayer.configuration.logger.log(:error, error_message)
          raise StandardError, error_message
        end
      when /text\/html/
        body
      else
        body # Return as raw content if content type is not recognized
      end
    else
      error_message = "Failed to fetch URL content: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  rescue StandardError => e
    Sublayer.configuration.logger.log(:error, "Error fetching URL content: #{e.message}")
    raise e
  end
end