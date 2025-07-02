require 'httparty'
require 'nokogiri'

# Description: Sublayer::Action responsible for scraping the content of a website.
# This action uses HTTParty to fetch the HTML content of a given URL and Nokogiri to parse and extract the text.
#
# It is initialized with a URL.
# It returns the extracted text content of the website.
#
# Example usage: When you want to analyze the text content of a webpage, summarize it, or use it as context for an LLM.

class ScrapeWebsiteContentAction < Sublayer::Actions::Base
  def initialize(url:)
    @url = url
  end

  def call
    begin
      response = HTTParty.get(@url)

      unless response.success?
        error_message = "HTTP request failed: \#{response.code} - \#{response.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end

      parsed_page = Nokogiri::HTML(response.body)
      text_content = parsed_page.text.gsub(/\s+/, ' ').strip # Remove extra whitespace

      Sublayer.configuration.logger.log(:info, "Successfully scraped content from \#{@url}")
      text_content
    rescue HTTParty::Error => e
      error_message = "HTTParty error: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Nokogiri::Error => e
      error_message = "Nokogiri error: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error scraping website content: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end