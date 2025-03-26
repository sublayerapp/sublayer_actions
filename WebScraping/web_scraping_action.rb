require 'nokogiri'
require 'httparty'

# Description: Sublayer::Action responsible for scraping structured data from a website.
# This action uses Nokogiri and HTTParty to fetch and parse the HTML content of a given URL,
# allowing for extraction of specific data based on CSS selectors or XPath expressions.
#
# It is initialized with a URL and a set of data extraction rules (CSS selectors or XPath expressions).
# It returns a hash containing the extracted data.
#
# Example usage: When you want to extract product information, news articles, or other structured data from a website for use in AI-driven workflows.

class WebScraping::WebScrapingAction < Sublayer::Actions::Base
  def initialize(url:, extraction_rules:)
    @url = url
    @extraction_rules = extraction_rules
  end

  def call
    begin
      response = HTTParty.get(@url)
      raise StandardError, "HTTP request failed with code: #{response.code}" unless response.success?

      html_doc = Nokogiri::HTML(response.body)
      extracted_data = {}

      @extraction_rules.each do |key, selector|
        extracted_data[key] = extract_data(html_doc, selector)
      end

      Sublayer.configuration.logger.log(:info, "Successfully scraped data from \#{@url}")
      extracted_data
    rescue HTTParty::Error => e
      error_message = "HTTParty error during web scraping: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during web scraping: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def extract_data(html_doc, selector)
    if selector.start_with?('//')
      # XPath expression
      html_doc.xpath(selector).map(&:text).map(&:strip)
    else
      # CSS selector
      html_doc.css(selector).map(&:text).map(&:strip)
    end
  end
end