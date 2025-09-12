require 'google_search'

# Description: Sublayer::Action responsible for performing a Google Search and returning the top search results.
# This action integrates with the Google Search API to gather information from the web.
#
# It is initialized with a query and optionally the number of results to return.
# It returns an array of search results, each containing title, URL, and snippet.
#
# Example usage: When you want to augment prompts with up-to-date information from the web or inform decision-making processes.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 5)
    @query = query
    @num_results = num_results
  end

  def call
    begin
      results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@query}' and retrieved #{results.size} results.")
      results
    rescue GoogleSearch::Error => e
      error_message = "Error performing Google search: #{e.message}"
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
    GoogleSearch.search(@query, num_results: @num_results)
  end
end