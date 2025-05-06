require 'httparty'

# Description: Sublayer::Action responsible for performing a web search using the DuckDuckGo API.
# This action integrates with DuckDuckGo's API via HTTParty to retrieve search results based on a query.
#
# It is initialized with a query string and returns an array of result objects.
#
# Example usage: When you want to augment an LLM prompt with up-to-date information from the web, or make decisions based on current events.

class DuckDuckGoSearchAction < Sublayer::Actions::Base
  include HTTParty
  base_uri 'api.duckduckgo.com'
  format :json

  def initialize(query:)
    @query = query
  end

  def call
    search_results
  rescue HTTParty::Error => e
    error_message = "HTTP error during search: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error performing DuckDuckGo search: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def search_results
    options = { query: { q: @query, format: 'json', pretty: 1 } }
    response = self.class.get('', options)

    if response.success?
      results = response['RelatedTopics'] || []
      Sublayer.configuration.logger.log(:info, "Successfully retrieved #{results.size} search results for query: #{@query}")
      results
    else
      error_message = "Failed to perform search: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end