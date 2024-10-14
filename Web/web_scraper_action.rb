require 'nokogiri'
require 'open-uri'

# Description: Sublayer::Action responsible for scraping specific information from a website.
# This action allows for flexible web scraping by specifying CSS selectors for desired elements.
#
# Requires: 'nokogiri' gem
# $ gem install nokogiri
# Or add `gem 'nokogiri'` to your Gemfile
#
# It is initialized with a URL and a hash of element names and their corresponding CSS selectors.
# It returns a hash with the scraped data.
#
# Example usage: When you want to extract specific information from a webpage for further processing or analysis in your Sublayer workflow.

class WebScraperAction < Sublayer::Actions::Base
  def initialize(url:, selectors:)
    @url = url
    @selectors = selectors
  end

  def call
    begin
      doc = Nokogiri::HTML(URI.open(@url))
      
      result = {}
      @selectors.each do |name, selector|
        elements = doc.css(selector)
        result[name] = elements.map(&:text).map(&:strip)
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
