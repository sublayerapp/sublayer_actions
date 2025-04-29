require 'open-uri'
require 'nokogiri'

# Description: Sublayer::Action responsible for scraping text content from a given URL.
# It is useful for extracting text for summaries or insights from web content.
#
# Requires: 'nokogiri' gem
# $ gem install nokogiri
# Or add `gem 'nokogiri'` to your Gemfile
#
# It is initialized with a url and returns the scraped text content.
#
# Example usage: When you need to extract text from a webpage for analysis or AI processing.

class URLScrapingAndTextExtractionAction < Sublayer::Actions::Base
  def initialize(url:)
    @url = url
  end

  def call
    scrape_text_from_url
  end

  private

  def scrape_text_from_url
    begin
      content = open(@url).read
      document = Nokogiri::HTML(content)
      text = document.xpath('//text()').map(&:text).join(" ").squeeze(" ").strip
      Sublayer.configuration.logger.log(:info, "Successfully extracted text from URL: #{@url}")
      text
    rescue OpenURI::HTTPError => e
      error_message = "Error scraping URL: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end