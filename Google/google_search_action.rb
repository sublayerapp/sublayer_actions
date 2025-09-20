require 'google_search'

# Description: Sublayer::Action that performs a Google Search with a given query and returns a list of snippets from the top search results.
# This is useful for augmenting prompts with real-time information or validating data.
#
# It is initialized with a query and returns an array of snippets from the search results.
#
# Example usage: When you want to augment a prompt with real-time information from Google Search.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:)
    @query = query
    @google_api_key = ENV['GOOGLE_API_KEY']
    @google_cse_id = ENV['GOOGLE_CSE_ID']
  end

  def call
    begin
      search_results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google Search for query: \#{@query}")
      search_results
    rescue GoogleSearch::Error => e
      error_message = "Error performing Google Search: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during Google Search: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def perform_search
    search = GoogleSearch.new(api_key: @google_api_key, cse_id: @google_cse_id)
    results = search.search(@query)
    results.map(&:snippet)
  end
end
