require 'nokogiri'
require 'open-uri'

# Description: Sublayer::Action responsible for scraping specific content from a given URL.
# This action allows for easy integration of web scraping capabilities into Sublayer workflows,
# enabling data collection from websites for AI analysis or change tracking over time.
#
# Requires: 'nokogiri' gem
# $ gem install nokogiri
# Or add `gem 'nokogiri'` to your Gemfile
#
# It is initialized with a URL and a CSS selector for the content to be scraped.
# It returns the scraped content as a string.
#
# Example usage: When you want to extract specific information from a webpage for use in AI analysis or monitoring.

class WebPageScraperAction < Sublayer::Actions::Base
  def initialize(url:, css_selector:)
    @url = url
    @css_selector = css_selector
  end

  def call
    begin
      doc = Nokogiri::HTML(URI.open(@url))
      content = doc.css(@css_selector).map(&:text).join('\n').strip
      
      if content.empty?
        error_message = "No content found for the given CSS selector: #{@css_selector}"
        Sublayer.configuration.logger.log(:warn, error_message)
        return nil
      end

      Sublayer.configuration.logger.log(:info, "Successfully scraped content from #{@url}")
      content
    rescue OpenURI::HTTPError => e
      error_message = "HTTP Error while scraping #{@url}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue SocketError => e
      error_message = "Network error while scraping #{@url}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error scraping #{@url}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end