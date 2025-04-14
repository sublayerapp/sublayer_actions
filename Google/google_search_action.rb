require 'google_search'

# Description: Sublayer::Action to perform a Google Search and return the results as a list of snippets.
#
# It is initialized with a query and optionally the number of results to return.
# It returns an array of search result snippets.
#
# Example usage: When you want to augment an LLM prompt with information from a Google search.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 5)
    @query = query
    @num_results = num_results
  end

  def call
    begin
      search_results = perform_google_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@query}'")
      search_results
    rescue GoogleSearch::Error => e
      error_message = "Error performing Google search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error during Google search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def perform_google_search
    GoogleSearch.results(@query, num_results: @num_results).map(&:snippet)
  end
end