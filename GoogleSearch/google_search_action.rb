require 'google_search'

# Description: Sublayer::Action that performs a Google Search query and returns the top search results.
# Useful for gathering real-time information or augmenting prompts with external data.
#
# It is initialized with a search query.
# It returns an array of the top search result URLs.
#
# Example usage: When you want to augment an LLM prompt with current events, or gather information about a topic the LLM may not know about.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:)
    @query = query
  end

  def call
    begin
      search_results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for query: #{@query}")
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
    GoogleSearch.results(@query, num_results: 5).map(&:uri)
  end
end