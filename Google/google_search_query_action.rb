require 'google_search'

# Description: Sublayer::Action responsible for performing a Google search query and returning the top results.
# This action integrates with the Google Search API to fetch relevant information based on a given query.
#
# It is initialized with a query and optionally the number of results to return (defaults to 5).
# It returns an array of search result items, each containing title, link, and snippet.
#
# Example usage: When you want to augment LLM prompts with real-time information from the web.

class GoogleSearchQueryAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 5)
    @query = query
    @num_results = num_results
    @api_key = ENV['GOOGLE_SEARCH_API_KEY']
    @cx = ENV['GOOGLE_SEARCH_ENGINE_ID'] # Custom Search Engine ID
  end

  def call
    begin
      search_results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@query}'")
      search_results
    rescue GoogleSearch::Error => e
      error_message = "Error during Google search: #{e.message}"
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
    search = GoogleSearch.new(@api_key, @cx)
    results = search.search(@query, num: @num_results)

    results.map do |item|
      {
        title: item.title,
        link: item.link,
        snippet: item.snippet
      }
    end
  end
end
