require 'google_search'

# Description: Sublayer::Action responsible for performing a Google Search and returning the top search results.
# This action uses the google_search gem to query Google and retrieve search results.
#
# It is initialized with a search query and optionally the number of results to return.
# It returns an array of search result objects, each containing a title, URL, and snippet.
#
# Example usage: When you want to augment prompts with up-to-date information from the web or perform automated research.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 5)
    @query = query
    @num_results = num_results
  end

  def call
    begin
      results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@query}' and retrieved #{results.size} results")
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
    api_key = ENV['GOOGLE_SEARCH_API_KEY']
    cx = ENV['GOOGLE_SEARCH_CX']

    search = GoogleSearch::Search.new(api_key: api_key, cx: cx)
    search.query(@query, num: @num_results)
  end
end
