require 'nokogiri'
require 'open-uri'

# Description: Sublayer::Action responsible for extracting the main textual content from a webpage, stripping away HTML and boilerplate.
# This action allows AI agents to easily process and summarize web content.
#
# It is initialized with a URL.
# It returns the extracted text content of the webpage.
#
# Example usage: When you want to summarize the content of a news article or blog post.

class WebpageExtractTextAction < Sublayer::Actions::Base
  def initialize(url:)
    @url = url
  end

  def call
    begin
      doc = Nokogiri::HTML(URI.open(@url))
      text_content = extract_main_text(doc)
      Sublayer.configuration.logger.log(:info, "Successfully extracted text from \#{@url}")
      text_content
    rescue OpenURI::HTTPError => e
      error_message = "HTTP error while fetching \#{@url}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error extracting text from \#{@url}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def extract_main_text(doc)
    # Remove navigation, headers, footers, and other boilerplate elements
    doc.search('nav', 'header', 'footer', 'aside', 'script', 'style').remove

    # Extract text from the remaining elements
    text_content = doc.xpath('//body//text()').to_a.join(' ')

    # Clean up the text
    text_content = text_content.gsub(/\s+/, ' ').strip # Remove multiple spaces

    text_content
  end
end