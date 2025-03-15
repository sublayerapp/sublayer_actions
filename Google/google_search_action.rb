require 'google_search_results'

# Description: Sublayer::Action responsible for performing a Google search and returning a snippet of the results.
#
# It is initialized with a search query.
# It returns a snippet of the search results as a string.
#
# Example usage: When you want to augment an LLM prompt with real-time information from the web.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:)
    @query = query
  end

  def call
    begin
      results = perform_search
      snippet = extract_snippet(results)
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@query}'")
      snippet
    rescue GoogleSearch::Error => e
      error_message = "Error performing Google search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error processing Google search results: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def perform_search
    client = GoogleSearch.new(q: @query, api_key: ENV['GOOGLE_SEARCH_API_KEY'])
    client.get_hash
  end

  def extract_snippet(results)
    # Extract the snippet from the search results.
    # This may need to be adjusted based on the structure of the Google Search Results API response.
    results.dig("organic_results", 0, "snippet") || "No snippet found."
  end
end
