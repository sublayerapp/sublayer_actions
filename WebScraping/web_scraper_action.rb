require 'nokogiri'
require 'open-uri'

# Description: Sublayer::Action responsible for scraping specific data from web pages.
# This action can be used to gather input data for AI analysis or to verify AI-generated information.
#
# Requires: 'nokogiri' gem
# $ gem install nokogiri
# Or add `gem 'nokogiri'` to your Gemfile
#
# It is initialized with a URL and a hash of CSS selectors for the data to be extracted.
# It returns a hash with the extracted data.
#
# Example usage: When you need to extract specific information from a website for AI analysis or verification.

class WebScraperAction < Sublayer::Actions::Base
  def initialize(url:, selectors:)
    @url = url
    @selectors = selectors
  end

  def call
    begin
      doc = Nokogiri::HTML(URI.open(@url))
      extracted_data = {}

      @selectors.each do |key, selector|
        elements = doc.css(selector)
        extracted_data[key] = elements.map(&:text).map(&:strip)
      end

      Sublayer.configuration.logger.log(:info, "Successfully scraped data from #{@url}")
      extracted_data
    rescue OpenURI::HTTPError => e
      error_message = "HTTP Error when scraping #{@url}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error scraping data from #{@url}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
