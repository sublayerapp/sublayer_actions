require 'google_search'

# Description: Sublayer::Action responsible for performing a Google Search and returning the top results.
# This action integrates with the Google Search API (using the google_search gem) to fetch relevant information based on a query.
#
# It is initialized with a query and an optional number of results (defaulting to 5).
# It returns an array of search results, each containing a title, URL, and snippet.
#
# Example usage: When you need to augment a prompt with up-to-date information from the web.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 5)
    @query = query
    @num_results = num_results
  end

  def call
    begin
      results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@query}' and retrieved #{results.size} results.")
      results
    rescue GoogleSearch::Error => e
      error_message = "Error during Google Search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error performing Google Search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def perform_search
    GoogleSearch.search(@query, num_results: @num_results).map do |result|
      {
        title: result.title,
        url: result.uri,
        snippet: result.snippet
      }
    end
  end
end
