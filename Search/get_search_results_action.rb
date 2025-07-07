require 'httparty'

# Description: Sublayer::Action responsible for retrieving search results from a search engine.
# This action uses the DuckDuckGo API to fetch the top search results for a given query.
#
# It is initialized with a query and an optional number of results.
# It returns an array of search result titles and URLs.
#
# Example usage: When you want to gather information from the web based on a search query.

class GetSearchResultsAction < Sublayer::Actions::Base
  include HTTParty
  base_uri 'api.duckduckgo.com'

  def initialize(query:, num_results: 5)
    @query = query
    @num_results = num_results
  end

  def call
    begin
      response = self.class.get('', query: { q: @query, format: 'json', pretty: 1 })

      if response.success?
        results = parse_results(response.parsed_response)
        Sublayer.configuration.logger.log(:info, "Successfully retrieved search results for query: \#{@query}")
        results
      else
        error_message = "Failed to retrieve search results: HTTP \#{response.code} - \#{response.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue HTTParty::Error => e
      error_message = "HTTP error during search: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error retrieving search results: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def parse_results(response)
    response['RelatedTopics'].map do |result|
      {
        'title' => result['Text'],
        'url' => result['FirstURL']
      }
    end
  end
end