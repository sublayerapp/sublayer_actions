require 'google_search'

# Description: Sublayer::Action to perform a Google search and return snippets of the top search results.
# Useful for augmenting prompts with real-time information.
#
# It is initialized with a search query and an optional number of results.  It returns an array of snippets from the search results.
#
# Example usage: When you want to augment a prompt with current events or information not available in the LLM's training data.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 3)
    @query = query
    @num_results = num_results
  end

  def call
    begin
      search_results = perform_search
      snippets = extract_snippets(search_results)
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@query}'")
      snippets
    rescue GoogleSearch::Error => e
      error_message = "Google Search failed: #{e.message}"
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
    # Replace with actual Google Search API call or gem usage
    # This is a placeholder
    # Ensure you have a gem like 'google_search' or implement the API calls directly
    # You'll likely need an API key as well

    # Example using a hypothetical google_search gem:
    # GoogleSearch.search(@query, num_results: @num_results)
    #
    # For now, return dummy data:
    [
      { title: "Dummy Result 1", snippet: "This is a snippet from dummy result 1." },
      { title: "Dummy Result 2", snippet: "This is a snippet from dummy result 2." },
      { title: "Dummy Result 3", snippet: "This is a snippet from dummy result 3." }
    ]
  end

  def extract_snippets(search_results)
    search_results.map { |result| result[:snippet] }
  end
end