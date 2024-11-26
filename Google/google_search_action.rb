require 'google_search_results'

# Description: Sublayer::Action responsible for performing a Google search and returning the top results.
# It uses the google_search_results gem to interact with the Google Search API.
#
# It is initialized with a query string and an optional number of results to return (defaults to 10).
# It returns an array of hashes, where each hash represents a search result with keys for title, link, and snippet.
#
# Example usage: When you want to retrieve information from Google search within your Sublayer workflow.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 10)
    @query = query
    @num_results = num_results
  end

  def call
    begin
      search_results = GoogleSearch.new(q: @query).get_hash[:organic_results]

      if search_results
        Sublayer.configuration.logger.log(:info, "Successfully executed Google search for '#{@query}' and retrieved #{search_results.size} results")
        return search_results.first(@num_results)
      else
        Sublayer.configuration.logger.log(:warn, "No results found for Google search '#{@query}'")
        return []
      end
    rescue GoogleSearch::GoogleSearchError => e
      error_message = "Error performing Google search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end