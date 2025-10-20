require 'google_search'

# Description: Sublayer::Action responsible for performing a Google Search and returning the top N results.
#
# It is initialized with a query and the number of results to return.
# It returns an array of hashes, where each hash contains the title, URL, and snippet of a search result.
#
# Example usage: When you want to augment a prompt with real-time information from the web.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 5)
    @query = query
    @num_results = num_results
    @api_key = ENV['GOOGLE_SEARCH_API_KEY']
    @cx = ENV['GOOGLE_SEARCH_CX'] # This is the Search Engine ID
  end

  def call
    begin
      search_results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google Search for '#{@query}'")
      search_results
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
    search = GoogleSearch::Search.new(api_key: @api_key, cx: @cx)

    results = search.search(@query, num: @num_results)

    results.map do |result|
      {
        title: result.title,
        url: result.link,
        snippet: result.snippet
      }
    end
  end
end
