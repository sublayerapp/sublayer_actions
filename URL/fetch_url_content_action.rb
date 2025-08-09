require 'net/http'
require 'uri'
require 'json'
require 'nokogiri'

# Description: Sublayer::Action responsible for fetching content from a given URL.
# The action supports fetching and returning content as a string, or parsed as JSON/XML.
#
# It is initialized with a url, and an optional format (string, json, xml).  Defaults to string.
# It returns the content of the URL, either as a string or a parsed object.
#
# Example usage: When you need to retrieve data from a web API or scrape content from a webpage.

class FetchURLContentAction < Sublayer::Actions::Base
  def initialize(url:, format: 'string')
    @url = url
    @format = format.downcase
  end

  def call
    begin
      uri = URI.parse(@url)
      response = Net::HTTP.get_response(uri)

      unless response.is_a?(Net::HTTPSuccess)
        error_message = "HTTP Error: \#{response.code} \#{response.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end

      content = response.body

      case @format
      when 'json'
        JSON.parse(content)
      when 'xml'
        Nokogiri::XML(content)
      else
        content
      end
    rescue URI::InvalidURIError => e
      error_message = "Invalid URL: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue JSON::ParserError => e
      error_message = "Error parsing JSON: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Nokogiri::XML::SyntaxError => e
      error_message = "Error parsing XML: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error fetching URL content: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end