# Description: Sublayer::Action responsible for fetching and extracting the text content from a given URL, stripping HTML tags.
#
# This action provides a way to ingest content from the web for use in prompts or other AI-driven processes.
#
# It is initialized with a URL and returns the text content of the webpage.
#
# Example usage: When you want to summarize a webpage, extract information from it, or use it as context for a Sublayer::Generator.

require 'httparty'
require 'nokogiri'

class GetWebpageContentAction < Sublayer::Actions::Base
  def initialize(url:)
    @url = url
  end

  def call
    begin
      response = HTTParty.get(@url)
      raise StandardError, "HTTP request failed with code: #{response.code}" unless response.success?

      html_doc = Nokogiri::HTML(response.body)
      text_content = html_doc.text.strip

      Sublayer.configuration.logger.log(:info, "Successfully fetched and extracted content from \#{@url}")
      text_content
    rescue HTTParty::Error => e
      error_message = "HTTParty error fetching \#{@url}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Nokogiri::XML::SyntaxError => e
      error_message = "Nokogiri XML Syntax error parsing \#{@url}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error getting webpage content from \#{@url}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end