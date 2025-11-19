require 'google_search'

# Description: Sublayer::Action responsible for performing a Google Search and returning snippets from the top results.
# Useful for augmenting prompts with up-to-date information, verifying facts, or gathering context.
#
# It is initialized with a query and an optional number of results (defaulting to 3).
# It returns an array of snippets from the Google Search results.
#
# Example usage: When you want to enrich a prompt with current information from the web or verify the accuracy of a statement.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 3)
    @query = query
    @num_results = num_results
    @api_key = ENV['GOOGLE_SEARCH_API_KEY']
    @cx = ENV['GOOGLE_SEARCH_ENGINE_ID'] # This is the Search Engine ID
  end

  def call
    begin
      search_results = perform_search
      snippets = extract_snippets(search_results)

      Sublayer.configuration.logger.log(:info, "Successfully performed Google Search for '#{@query}' and extracted snippets.")

      snippets
    rescue GoogleSearch::Error => e
      error_message = "Google Search API error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error performing Google Search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def perform_search
    GoogleSearch.search(query: @query, api_key: @api_key, cx: @cx, num: @num_results)
  end

  def extract_snippets(search_results)
    search_results.map { |result| result.snippet }
  end
end
