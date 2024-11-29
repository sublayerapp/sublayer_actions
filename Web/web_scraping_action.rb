require 'nokogiri'
require 'open-uri'

# Description: Sublayer::Action responsible for scraping specified data from a given URL.
# This action allows for easy integration of web scraping capabilities into Sublayer workflows,
# enabling the extraction of structured data from websites for use in generators or other actions.
#
# Requires: 'nokogiri' gem
# $ gem install nokogiri
# Or add `gem 'nokogiri'` to your Gemfile
#
# It is initialized with a URL and a hash of CSS selectors for the data to be extracted.
# It returns a hash with the extracted data.
#
# Example usage: When you want to extract specific information from a webpage to use in a Sublayer::Generator or other actions.

class WebScrapingAction < Sublayer::Actions::Base
  def initialize(url:, selectors:)
    @url = url
    @selectors = selectors
  end

  def call
    begin
      page = Nokogiri::HTML(URI.open(@url))
      
      result = {}
      @selectors.each do |key, selector|
        result[key] = page.css(selector).map(&:text).map(&:strip)
      end

      Sublayer.configuration.logger.log(:info, "Successfully scraped data from #{@url}")
      result
    rescue OpenURI::HTTPError => e
      error_message = "HTTP Error while scraping #{@url}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error while scraping #{@url}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
