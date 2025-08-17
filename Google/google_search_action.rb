require 'google_search'

# Description: Sublayer::Action responsible for performing a Google Search and returning a list of URLs and snippets from the search results.
#
# It is initialized with a query and optionally the number of results to return.
# It returns an array of hashes, where each hash contains the URL and snippet from the search result.
#
# Example usage: When you want to augment your LLM prompt with information from a Google Search.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 5)
    @query = query
    @num_results = num_results
  end

  def call
    begin
      results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google Search for '#{@query}'")
      results
    rescue GoogleSearch::Error => e
      error_message = "Error performing Google Search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during Google Search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def perform_search
    search = GoogleSearch.new(query: @query)
    search.search(@num_results).map do |result|
      {
        url: result.uri,
        snippet: result.text
      }
    end
  end
end