require 'nokogiri'
require 'open-uri'

# Description: Sublayer::Action responsible for scraping content from specified web pages and returning structured data.
# This action allows easy integration of web data into Sublayer workflows, expanding the capabilities of data acquisition beyond APIs.
#
# It is initialized with a URL and scraping rules, and returns the structured data based on the rules specified.
#
# Example usage: When you want to scrape data from a website for use in an AI-driven analysis or process.

class WebScrapingAction < Sublayer::Actions::Base
  def initialize(url:, scraping_rules: {})
    @url = url
    @scraping_rules = scraping_rules
  end

  def call
    scrape_content
  rescue OpenURI::HTTPError => e
    error_message = "HTTP error during web scraping: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error scraping web content: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def scrape_content
    document = open_url(@url)
    parsed_content = Nokogiri::HTML(document)
    extract_data(parsed_content)
  end

  def open_url(url)
    URI.open(url)
  end

  def extract_data(parsed_content)
    @scraping_rules.each_with_object({}) do |(key, rule), result|
      result[key] = parsed_content.css(rule).map(&:text).join(', ')
    end
  end
end