require 'google_search'

# Description: Sublayer::Action responsible for performing a Google search and returning the top N results.
# Each result includes the title, URL, and snippet. Useful for augmenting prompts with real-time information.
#
# It is initialized with a query and the number of results to return (default is 3).
# It returns an array of hashes, where each hash contains the title, URL, and snippet of a search result.
#
# Example usage: When you want to augment a prompt with the latest information from the web.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 3)
    @query = query
    @num_results = num_results
  end

  def call
    begin
      results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@query}' and retrieved #{@num_results} results.")
      results
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
    api_key = ENV['GOOGLE_SEARCH_API_KEY']
    cx = ENV['GOOGLE_SEARCH_ENGINE_ID']

    search = GoogleSearch::Search.new(api_key: api_key, cx: cx)
    search.query(@query, start: 1, num: @num_results)

    search.results.map do |result|
      {
        title: result.title,
        url: result.link,
        snippet: result.snippet
      }
    end
  end
end