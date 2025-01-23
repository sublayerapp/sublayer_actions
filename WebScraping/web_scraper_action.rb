require 'nokogiri'
require 'open-uri'

# Description: Sublayer::Action responsible for scraping specific data from a given website.
# This action allows for configurable web scraping, which can be useful for gathering input data for AI analysis.
#
# Requires: 'nokogiri' gem
# $ gem install nokogiri
# Or add `gem 'nokogiri'` to your Gemfile
#
# It is initialized with a URL and a hash of CSS selectors for data extraction.
# It returns a hash containing the scraped data.
#
# Example usage: When you want to extract specific information from a website for further processing or analysis in an AI workflow.

class WebScraperAction < Sublayer::Actions::Base
  def initialize(url:, selectors:)
    @url = url
    @selectors = selectors
  end

  def call
    begin
      doc = Nokogiri::HTML(URI.open(@url))
      scraped_data = {}

      @selectors.each do |key, selector|
        elements = doc.css(selector)
        scraped_data[key] = elements.map(&:text).map(&:strip)
      end

      Sublayer.configuration.logger.log(:info, "Successfully scraped data from #{@url}")
      scraped_data
    rescue OpenURI::HTTPError => e
      error_message = "HTTP Error while scraping #{@url}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error scraping #{@url}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
