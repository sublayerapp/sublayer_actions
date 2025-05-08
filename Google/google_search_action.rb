require 'google_search'

# Description: Sublayer::Action responsible for performing a Google search and returning the top results.
# This action allows the agent to gather real-time information from the web based on a query.
#
# It is initialized with a search_query and an optional num_results (defaulting to 5).
# It returns an array of strings, each representing a snippet from the top search results.
#
# Example usage: When you need to augment an LLM prompt with current information, or when the agent needs to answer a question that requires up-to-date knowledge.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(search_query:, num_results: 5)
    @search_query = search_query
    @num_results = num_results
    @api_key = ENV['GOOGLE_SEARCH_API_KEY']
    @cx = ENV['GOOGLE_SEARCH_ENGINE_ID']
  end

  def call
    begin
      search_results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@search_query}'")
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

  def perform_search
    search = GoogleSearch.new(@api_key, @cx)
    results = search.search(@search_query, num: @num_results)

    results.spelling_fix! unless results.spelling_fixed
    results.to_a.map { |result| result.snippet }
  end
end