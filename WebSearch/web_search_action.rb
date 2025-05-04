require 'httparty'
require 'nokogiri'

# Description: Sublayer::Action responsible for performing a web search and returning the top results.
# This action uses the DuckDuckGo API to perform the search and Nokogiri to parse the HTML results.
#
# It is initialized with a search query and returns a list of URLs and snippets from the search results.
#
# Example usage: When you need to augment a prompt with up-to-date information from the web.

class WebSearchAction < Sublayer::Actions::Base
  include HTTParty
  format :html

  def initialize(query:)
    @query = query
  end

  def call
    search_results
  rescue HTTParty::Error => e
    error_message = "HTTP error during web search: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error during web search: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def search_results
    base_uri = "https://duckduckgo.com/"
    query = { "q" => @query }

    response = self.class.get(base_uri, query: query)

    if response.success?
      parse_results(response.body)
    else
      error_message = "Web search failed: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  def parse_results(html)
    doc = Nokogiri::HTML(html)
    results = []

    doc.css('.result').each do |result|
      title = result.css('.result__a').text.strip
      url = result.css('.result__a').attr('href').value.strip
      snippet = result.css('.result__snippet').text.strip

      results << { title: title, url: url, snippet: snippet }
    end

    Sublayer.configuration.logger.log(:info, "Web search completed successfully with #{results.count} results.")
    results
  end
end