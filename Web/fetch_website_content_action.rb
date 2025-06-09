require 'httparty'
require 'nokogiri'

# Description: Sublayer::Action responsible for fetching and parsing the HTML content of a website.
# This action uses HTTParty to make the HTTP request and Nokogiri to parse the HTML.
#
# It is initialized with a URL and returns the parsed HTML content as a Nokogiri::HTML::Document.
#
# Example usage: When you want to extract information from a website for use in a Sublayer::Generator.

class FetchWebsiteContentAction < Sublayer::Actions::Base
  def initialize(url:)
    @url = url
  end

  def call
    begin
      response = HTTParty.get(@url)
      raise StandardError, "HTTP request failed with code: #{response.code}" unless response.success?

      html_content = Nokogiri::HTML(response.body)
      Sublayer.configuration.logger.log(:info, "Successfully fetched and parsed HTML content from \#{@url}")
      html_content
    rescue HTTParty::Error => e
      error_message = "HTTParty error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Nokogiri::Error => e
      error_message = "Nokogiri error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error fetching website content: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end