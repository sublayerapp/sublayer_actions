require 'google_search'

# Description: Sublayer::Action responsible for performing a Google Search and returning snippets of the results.
# Useful for augmenting prompts with up-to-date information.
#
# It is initialized with a query and optionally the number of results to return.
# It returns an array of snippets from the search results.
#
# Example usage: When you want to augment a prompt with the latest information from the web.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 3)
    @query = query
    @num_results = num_results
    @api_key = ENV['GOOGLE_SEARCH_API_KEY']
    @cx = ENV['GOOGLE_SEARCH_CX'] # Programmable Search Engine ID
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
    search = GoogleSearch.new(@api_key, @cx)
    search.search(@query, num: @num_results)
  end

  def extract_snippets(search_results)
    search_results.map { |result| result.snippet }
  end
end