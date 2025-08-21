require 'open_uri'
require 'nokogiri'

# Description: Sublayer::Action responsible for summarizing the text content of a webpage.
# It fetches the content from a given URL, extracts the main text, and returns it.
#
# It is initialized with a URL.
# It returns the summarized text content of the webpage.
#
# Example usage: When you want to extract information from articles, blog posts, or documentation pages for use in prompts or decision-making.

class SummarizeWebpageAction < Sublayer::Actions::Base
  def initialize(url:)
    @url = url
  end

  def call
    begin
      html = URI.open(@url).read
      doc = Nokogiri::HTML(html)
      text_content = extract_text_content(doc)
      Sublayer.configuration.logger.log(:info, "Successfully summarized webpage from \#{@url}")
      text_content
    rescue OpenURI::HTTPError => e
      error_message = "Error fetching webpage: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Nokogiri::Error => e
      error_message = "Error parsing HTML: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error summarizing webpage: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def extract_text_content(doc)
    # Remove script and style elements
    doc.xpath('//script | //style').remove

    # Extract text, removing extra whitespace
    text_content = doc.xpath('//body').text.gsub(/\s+/, ' ').strip

    text_content
  end
end