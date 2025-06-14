require 'google_search_results'

# Description: Sublayer::Action responsible for performing a Google search and returning snippets of the results.
#
# This action allows for gathering real-time information or performing research tasks within a Sublayer workflow.
#
# It is initialized with a search query and optionally a number of results to return.
# It returns an array of snippets from the search results.
#
# Example usage: When you want to augment an LLM prompt with real-time information from the web.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 5)
    @query = query
    @num_results = num_results
    @api_key = ENV['GOOGLE_SEARCH_API_KEY']
  end

  def call
    begin
      search_results = perform_search
      snippets = extract_snippets(search_results)
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@query}' and retrieved #{snippets.size} snippets.")
      snippets
    rescue GoogleSearch::Error => e
      error_message = "Error performing Google search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error processing Google search results: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def perform_search
    params = {
      q: @query,
      api_key: @api_key,
      num: @num_results,
    }

    GoogleSearch.search(params)
  end

  def extract_snippets(search_results)
    search_results[:organic_results].map { |result| result[:snippet] }
  end
end
