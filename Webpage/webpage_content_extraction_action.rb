require 'httparty'
require 'nokogiri'

# Description: Sublayer::Action responsible for extracting the main content from a webpage.
# It uses HTTParty to fetch the webpage and Nokogiri to parse the HTML and remove boilerplate.
#
# It is initialized with a URL and returns the extracted text content of the webpage.
#
# Example usage: When you want to analyze or summarize the main content of a webpage using an AI model.

class WebpageContentExtractionAction < Sublayer::Actions::Base
  def initialize(url:)
    @url = url
  end

  def call
    begin
      response = HTTParty.get(@url)
      raise StandardError, "HTTP request failed with code: #{response.code}" unless response.success?

      html_doc = Nokogiri::HTML(response.body)
      
      # Remove common boilerplate elements (headers, footers, nav, ads, etc.)
      html_doc.xpath('//header', '//footer', '//nav', '//aside', '//script', '//style', '//comment()').remove

      # Extract the main content by selecting the body and getting the text
      main_content = html_doc.xpath('//body').text.strip

      Sublayer.configuration.logger.log(:info, "Successfully extracted content from \#{@url}")
      main_content
    rescue HTTParty::Error => e
      error_message = "HTTParty error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Nokogiri::Error => e
      error_message = "Nokogiri error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error extracting content from \#{@url}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end
