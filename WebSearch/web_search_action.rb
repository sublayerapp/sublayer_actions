require 'httparty'
require 'nokogiri'

# Description: Sublayer::Action that performs a web search using DuckDuckGo and returns a list of result URLs and snippets.
#
# It is initialized with a search query.
# It returns an array of hashes, where each hash contains the 'title', 'url', and 'snippet' of a search result.
#
# Example usage: When you want to augment an LLM prompt with information gathered from a web search.

class WebSearchAction < Sublayer::Actions::Base
  include HTTParty
  format :html

  def initialize(query:)
    @query = query
    @search_url = 'https://duckduckgo.com'
  end

  def call
    begin
      response = self.class.get(@search_url, query: { q: @query })
      raise StandardError, "HTTP request failed" unless response.success?

      parse_results(response.body)
    rescue HTTParty::Error => e
      error_message = "HTTP error during web search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during web search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def parse_results(html)
    doc = Nokogiri::HTML(html)
    results = []

    doc.css('.result').each do |result_node|
      title_node = result_node.at_css('.result__a')
      url_node = result_node.at_css('.result__url')
      snippet_node = result_node.at_css('.result__snippet')

      next unless title_node && url_node && snippet_node

      title = title_node.text.strip
      url = url_node['href']
      snippet = snippet_node.text.strip

      results << { title: title, url: url, snippet: snippet }
    end

    results
  end
end