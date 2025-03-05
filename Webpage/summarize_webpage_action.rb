# Description: Sublayer::Action responsible for summarizing the content of a webpage given a URL.
# It leverages gems like `nokogiri` and `open-uri` to fetch and parse the HTML, then extracts the text content for summarization.
# The extracted text is sent to a summarization generator for processing.
#
# It is initialized with a URL and returns a summary of the webpage content.
#
# Example usage: When you want to automatically summarize articles or documentation from a URL for use in a Sublayer::Generator.

require 'nokogiri'
require 'open-uri'

class SummarizeWebpageAction < Sublayer::Actions::Base
  def initialize(url:, summarization_generator:)
    @url = url
    @summarization_generator = summarization_generator
  end

  def call
    begin
      html = URI.open(@url).read
      doc = Nokogiri::HTML(html)
      text_content = doc.xpath('//body//text()').to_a.join(' ')
      summary = @summarization_generator.call(text_content)

      Sublayer.configuration.logger.log(:info, "Successfully summarized webpage from \#{@url}")
      summary
    rescue OpenURI::HTTPError => e
      error_message = "Error fetching webpage: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Nokogiri::SyntaxError => e
      error_message = "Error parsing HTML: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error summarizing webpage: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end