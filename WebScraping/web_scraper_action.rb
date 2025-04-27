require 'nokogiri'
require 'open-uri'

# Description: Sublayer::Action responsible for scraping structured data from specified web pages.
# This action allows for easy integration of web scraping capabilities into Sublayer workflows,
# enabling data collection for AI analysis or keeping information up-to-date.
#
# Requires: 'nokogiri' gem
# $ gem install nokogiri
# Or add `gem 'nokogiri'` to your Gemfile
#
# It is initialized with a URL and a hash of CSS selectors for the data to be extracted.
# It returns a hash with the extracted data.
#
# Example usage: When you want to gather specific information from a web page for analysis or processing in an AI workflow.

class WebScraperAction < Sublayer::Actions::Base
  def initialize(url:, selectors:)
    @url = url
    @selectors = selectors
  end

  def call
    begin
      page = Nokogiri::HTML(URI.open(@url))
      data = extract_data(page)
      Sublayer.configuration.logger.log(:info, "Successfully scraped data from #{@url}")
      data
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

  private

  def extract_data(page)
    @selectors.transform_values do |selector|
      elements = page.css(selector)
      elements.size == 1 ? elements.first.text.strip : elements.map(&:text).map(&:strip)
    end
  end
end
