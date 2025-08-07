require 'readability'
require 'open-uri'
require 'nokogiri'

# Description: Sublayer::Action responsible for extracting clean, formatted content from a webpage URL.
# Uses the Readability algorithm to parse and clean webpage content, making it suitable for AI processing.
#
# Requires: 'ruby-readability' gem
# $ gem install ruby-readability
# Or add `gem 'ruby-readability'` to your Gemfile
#
# It is initialized with a URL and optional parameters for content extraction.
# Returns a hash containing the extracted title, content, and metadata.
#
# Example usage: When you want to feed web content into an LLM for analysis, summarization,
# or other natural language processing tasks while removing ads, navigation, and other noise.

class WebpageContentExtractAction < Sublayer::Actions::Base
  def initialize(url:, remove_unlikely_candidates: true, min_text_length: 25)
    @url = url
    @remove_unlikely_candidates = remove_unlikely_candidates
    @min_text_length = min_text_length
  end

  def call
    begin
      html = fetch_webpage
      extracted_content = extract_content(html)
      
      Sublayer.configuration.logger.log(:info, "Successfully extracted content from #{@url}")
      
      extracted_content
    rescue OpenURI::HTTPError => e
      error_message = "HTTP error while fetching webpage: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error extracting webpage content: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def fetch_webpage
    URI.open(@url, 'User-Agent' => 'Sublayer WebpageContentExtractAction/1.0').read
  end

  def extract_content(html)
    doc = Readability::Document.new(html,
      :remove_unlikely_candidates => @remove_unlikely_candidates,
      :min_text_length => @min_text_length
    )

    {
      title: doc.title,
      content: doc.content,
      author: doc.author,
      excerpt: doc.description,
      word_count: doc.content.split(/\s+/).length,
      reading_time_minutes: (doc.content.split(/\s+/).length / 200.0).ceil # Assuming 200 WPM reading speed
    }
  end
end