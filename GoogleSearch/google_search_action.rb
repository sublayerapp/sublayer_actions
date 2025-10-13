require 'google_search'

# Description: Sublayer::Action responsible for performing a Google Search and returning the top 'n' results.
# Each result includes the title, URL, and snippet.
#
# It is initialized with a query and the number of results to return (n).
# It returns an array of hashes, each containing the title, URL, and snippet of a search result.
#
# Example usage: When you want to gather real-time information or augment prompts with external data from Google Search.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, n: 3)
    @query = query
    @n = n
  end

  def call
    begin
      results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google Search for query: \#{@query}")
      results
    rescue GoogleSearch::Error => e
      error_message = "Error performing Google Search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "An unexpected error occurred during Google Search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise
    end
  end

  private

  def perform_search
    search = GoogleSearch.new(key: ENV['GOOGLE_SEARCH_API_KEY'], cx: ENV['GOOGLE_SEARCH_ENGINE_ID'])
    results = search.search(query: @query, num: @n)

    results.map do |item|
      {
        title: item.title,
        url: item.link,
        snippet: item.snippet
      }
    end
  end
end
