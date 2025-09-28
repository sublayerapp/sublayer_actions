require 'google_search'

# Description: Sublayer::Action responsible for performing a Google Search and returning the results.
# It uses the google_search gem to interact with the Google Search API.
#
# It is initialized with a query string and returns an array of search results,
# each containing a title, URL, and snippet.
#
# Example usage: When you want to augment an LLM prompt with real-time information from the web.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:)
    @query = query
  end

  def call
    begin
      search_results = perform_search
      Sublayer.configuration.logger.log(:info, "Google search successful for query: #{@query}")
      search_results
    rescue GoogleSearch::Error => e
      error_message = "Google search failed: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during Google search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def perform_search
    GoogleSearch.search(@query) do |item|
      {
        title: item.title,
        url: item.link,
        snippet: item.snippet
      }
    end
  end
end