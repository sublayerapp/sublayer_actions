require 'google_search'

# Description: Sublayer::Action responsible for performing a Google Search query and returning a list of search results.
# This action integrates with the Google Search API to fetch relevant information based on a search query.
#
# It is initialized with a query string and an optional number of results to return (defaults to 5).
# It returns an array of hashes, where each hash contains the title, URL, and snippet of a search result.
#
# Example usage: When you want to gather up-to-date information or validate facts in your Sublayer workflow.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 5)
    @query = query
    @num_results = num_results
  end

  def call
    begin
      search_results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@query}' and retrieved #{search_results.size} results.")
      search_results
    rescue GoogleSearch::Error => e
      error_message = "Error performing Google search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "An unexpected error occurred during the Google search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def perform_search
    api_key = ENV['GOOGLE_SEARCH_API_KEY']
    cx = ENV['GOOGLE_SEARCH_ENGINE_ID'] # This is the Search Engine ID

    raise StandardError, "GOOGLE_SEARCH_API_KEY environment variable not set." unless api_key
    raise StandardError, "GOOGLE_SEARCH_ENGINE_ID environment variable not set." unless cx

    search = GoogleSearch::Search.new(api_key: api_key, cx: cx)

    results = search.search(@query, num: @num_results)

    results.map do |result|
      {
        title: result.title,
        url: result.link,
        snippet: result.snippet
      }
    end
  end
end