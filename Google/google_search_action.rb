require 'google_search'

# Description: Sublayer::Action responsible for performing a Google Search and returning a list of URLs and snippets.
# This action integrates with the Google Search API and returns search results based on the provided query.
#
# It is initialized with a query string.
# It returns an array of search results, where each result contains a title, URL, and snippet.
#
# Example usage: When you want to augment an LLM prompt with real-time information from a Google Search.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:)
    @query = query
  end

  def call
    begin
      search_results = perform_search
      Sublayer.configuration.logger.log(:info, "Google search performed successfully for query: \#{@query}")
      search_results
    rescue GoogleSearch::Error => e
      error_message = "Error performing Google search: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during Google search: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def perform_search
    GoogleSearch.search(@query, api_key: ENV['GOOGLE_SEARCH_API_KEY'], cx: ENV['GOOGLE_SEARCH_CX_ID']).map do |result|
      {
        title: result.title,
        url: result.link,
        snippet: result.snippet
      }
    end
  end
end
