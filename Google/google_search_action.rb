require 'google_search'

# Description: Sublayer::Action responsible for performing a Google search and returning the top results.
# This action uses the google_search gem to query Google and extract relevant information from the search results.
#
# It is initialized with a search query and optionally the number of results to return.
# It returns an array of search results, each containing the title, URL, and snippet of the result.
#
# Example usage: When you want to gather information from the web based on a specific query in your Sublayer workflow.

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
      error_message = "Error performing Google search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error during Google search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def perform_search
    search = GoogleSearch.new(query: @query)
    search.get_results(@num_results).map do |result|
      {
        title: result.title,
        url: result.link,
        snippet: result.snippet
      }
    end
  end
end