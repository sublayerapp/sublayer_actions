require 'nokogiri'
require 'open-uri'

# Description: Sublayer::Action responsible for scraping content from a given URL.
# This action allows for easy integration of web scraping capabilities into Sublayer workflows,
# enabling data gathering from websites for AI analysis or generation tasks.
#
# Requires: 'nokogiri' gem
# $ gem install nokogiri
# Or add `gem 'nokogiri'` to your Gemfile
#
# It is initialized with a URL and optional CSS selector.
# It returns the scraped content as a string.
#
# Example usage: When you want to gather data from a specific website for use in AI analysis or generation tasks.

class WebPageScraperAction < Sublayer::Actions::Base
  def initialize(url:, css_selector: 'body')
    @url = url
    @css_selector = css_selector
  end

  def call
    begin
      doc = Nokogiri::HTML(URI.open(@url))
      content = doc.css(@css_selector).text.strip
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