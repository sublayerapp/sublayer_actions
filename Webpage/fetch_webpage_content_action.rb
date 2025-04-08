require 'open-uri'
require 'nokogiri'

# Description: Sublayer::Action responsible for fetching and extracting the main text content from a webpage.
# It takes a URL as input and returns the cleaned text content, removing HTML tags and boilerplate.
# This action is useful for scraping content from webpages to be used in Sublayer::Generators.
#
# Example usage: When you want to summarize a webpage, extract information from it, or use its content in an AI-driven workflow.

class Webpage/fetch_webpage_content_action.rb < Sublayer::Actions::Base
  def initialize(url:)
    @url = url
  end

  def call
    begin
      html = URI.open(@url).read
      doc = Nokogiri::HTML(html)
      text_content = extract_main_content(doc)

      Sublayer.configuration.logger.log(:info, "Successfully fetched and extracted content from \#{@url}")
      text_content
    rescue OpenURI::HTTPError => e
      error_message = "Error fetching webpage: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Nokogiri::HTML::SyntaxError => e
      error_message = "Error parsing HTML: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error fetching and extracting content: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def extract_main_content(doc)
    # This is a simplified example.  More sophisticated extraction might be needed
    # depending on the target website.  Consider using a gem like 'readability' for
    # more robust content extraction.

    # Remove script and style elements
    doc.search('script', 'style').remove

    # Extract text and normalize whitespace
    text_content = doc.text.gsub(/\s+/, ' ').strip

    text_content
  end
end