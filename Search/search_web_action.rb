require 'httparty'
require 'nokogiri'

# Description: Sublayer::Action responsible for performing a search query on a search engine and returning the top search results.
# This action uses the DuckDuckGo search engine via its HTML interface to avoid API keys.
#
# It is initialized with a query and optionally the number of results to return.
# It returns an array of search result hashes, each containing 'title' and 'link'.
#
# Example usage: When you need to augment a prompt with real-time information from the web.

class SearchWebAction < Sublayer::Actions::Base
  include HTTParty
  format :html

  def initialize(query:, num_results: 5)
    @query = query
    @num_results = num_results
  end

  def call
    search
  rescue HTTParty::Error => e
    error_message = "HTTP error during search: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error during web search: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def search
    url = "https://duckduckgo.com/html/?q=#{URI.encode_www_form_component(@query)}"
    response = self.class.get(url)

    if response.success?
      parse_results(response.body)
    else
      error_message = "Search failed: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  def parse_results(html)
    doc = Nokogiri::HTML(html)
    results = []

    doc.css('.results .result').take(@num_results).each do |result_element|
      title_element = result_element.at_css('.result__title a')
      link_element = result_element.at_css('.result__url')

      if title_element && link_element
        title = title_element.text.strip
        link = link_element['href'].strip
        results << { title: title, link: link }
      end
    end

    Sublayer.configuration.logger.log(:info, "Successfully retrieved search results for query: #{@query}")
    results
  end
end