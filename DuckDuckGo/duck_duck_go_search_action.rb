require 'httparty'

# Description: Sublayer::Action responsible for performing a DuckDuckGo search and returning snippets of the top search results.
#
# It is initialized with a query string and an optional number of results to return (defaulting to 3).
# It returns an array of snippets from the search results.
#
# Example usage: When you want to augment a prompt with real-time information from the web using DuckDuckGo.

class DuckDuckGoSearchAction < Sublayer::Actions::Base
  include HTTParty
  base_uri 'api.duckduckgo.com'

  def initialize(query:, num_results: 3)
    @query = query
    @num_results = num_results
  end

  def call
    search_results = perform_search
    extract_snippets(search_results)
  rescue HTTParty::Error => e
    error_message = "HTTP error during DuckDuckGo search: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error performing DuckDuckGo search: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def perform_search
    options = {
      query: {
        q: @query,
        format: 'json',
        pretty: 0
      }
    }

    response = self.class.get('', options)

    if response.success?
      response.parsed_response['RelatedTopics']
    else
      error_message = "DuckDuckGo search failed: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  def extract_snippets(search_results)
    snippets = []
    search_results.each do |result|
      next unless result['Text']

      snippets << result['Text']
      break if snippets.length >= @num_results
    end

    Sublayer.configuration.logger.log(:info, "Successfully retrieved #{snippets.size} snippets from DuckDuckGo for query: #{@query}")
    snippets
  end
end