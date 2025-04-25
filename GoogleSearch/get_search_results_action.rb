require 'google_search'

# Description: Sublayer::Action responsible for retrieving the top search results from a search engine for a specified query.
#
# It is initialized with a query and optionally the number of results to return.
# It returns an array of search result URLs.
#
# Example usage: When you want to augment an LLM prompt with current information from the web.

class GetSearchResultsAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 5)
    @query = query
    @num_results = num_results
    @api_key = ENV['GOOGLE_SEARCH_API_KEY']
    @cx = ENV['GOOGLE_SEARCH_CX']
  end

  def call
    begin
      search_results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully retrieved search results for query: #{@query}")
      search_results
    rescue GoogleSearch::Error => e
      error_message = "Error during search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error retrieving search results: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def perform_search
    search = GoogleSearch::Search.new(@api_key, @cx)
    response = search.get_search(@query, num: @num_results)
    response.results.map(&:link)
  end
end