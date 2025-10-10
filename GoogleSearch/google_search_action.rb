require 'google_search'

# Description: Sublayer::Action responsible for performing a Google Search and returning the top search results.
# This action integrates with the Google Search API to fetch relevant information based on a query.
#
# It is initialized with a search_query and optionally the number of results to return.
# It returns an array of search result URLs.
#
# Example usage: When you want to augment an LLM prompt with real-time information from the web, or to verify the accuracy of LLM-generated content.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(search_query:, num_results: 5)
    @search_query = search_query
    @num_results = num_results
    @api_key = ENV['GOOGLE_SEARCH_API_KEY']
    @cx = ENV['GOOGLE_SEARCH_CX'] # Custom Search Engine ID
  end

  def call
    begin
      search_results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google Search for '#{@search_query}'")
      search_results
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
    search = GoogleSearch::Search.new(@api_key, @cx)
    results = search.search(@search_query, num: @num_results)

    results.map(&:url)
  end
end