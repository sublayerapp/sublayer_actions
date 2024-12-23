require 'nokogiri'
require 'open-uri'

# Description: Sublayer::Action responsible for web scraping specific data from a given URL.
# This action allows for flexible extraction of data from web pages, which can be used
# as input for AI analysis or other Sublayer workflows.
#
# Requires: 'nokogiri' gem
# $ gem install nokogiri
# Or add `gem 'nokogiri'` to your Gemfile
#
# It is initialized with a URL and a hash of CSS selectors for data extraction.
# It returns a hash with the extracted data.
#
# Example usage: When you want to extract specific data from a web page for AI analysis or processing.

class WebScrapingAction < Sublayer::Actions::Base
  def initialize(url:, selectors:)
    @url = url
    @selectors = selectors
  end

  def call
    begin
      doc = Nokogiri::HTML(URI.open(@url))
      result = {}

      @selectors.each do |key, selector|
        elements = doc.css(selector)
        result[key] = elements.map(&:text).map(&:strip)
      end

      Sublayer.configuration.logger.log(:info, "Successfully scraped data from #{@url}")
      result
    rescue OpenURI::HTTPError => e
      error_message = "HTTP Error while scraping #{@url}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Nokogiri::XML::SyntaxError => e
      error_message = "Parsing Error while scraping #{@url}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error while scraping #{@url}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end