require 'httparty'
require 'nokogiri'

# Description: Sublayer::Action responsible for scraping data from a website using HTTParty and Nokogiri.
# It retrieves the content of elements matching a specified CSS selector from a given URL.
#
# It is initialized with a URL and a CSS selector.
# It returns the text content of the selected elements.
#
# Example usage: When you need to extract specific data from a website for use in an AI workflow,
# such as product prices, news headlines, or other structured information.

class HTTPartyWebScrapingAction < Sublayer::Actions::Base
  include HTTParty

  def initialize(url:, css_selector:)
    @url = url
    @css_selector = css_selector
  end

  def call
    begin
      response = self.class.get(@url)
      raise StandardError, "HTTP request failed with code: #{response.code}" unless response.success?

      parsed_page = Nokogiri::HTML(response.body)
      elements = parsed_page.css(@css_selector)

      scraped_data = elements.map(&:text).map(&:strip).reject(&:empty?)

      if scraped_data.empty?
        Sublayer.configuration.logger.log(:warn, "No elements found matching CSS selector '#{@css_selector}' at URL '#{@url}'")
      else
        Sublayer.configuration.logger.log(:info, "Successfully scraped data from URL '#{@url}' using CSS selector '#{@css_selector}'")
      end

      scraped_data
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
end