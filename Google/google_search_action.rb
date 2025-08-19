require 'google_search'

# Description: Sublayer::Action responsible for performing a Google Search and returning a list of URLs with titles and snippets.
# This action allows for easy integration of Google Search into Sublayer workflows,
# enabling agents to gather information from the web.
#
# It is initialized with a query and optionally the number of results to return.
# It returns an array of hashes, each containing the title, URL, and snippet of a search result.
#
# Example usage: When you want an AI agent to gather information from the web to answer a question or perform a task.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 5)
    @query = query
    @num_results = num_results
  end

  def call
    begin
      search_results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google Search for '#{@query}'")
      search_results
    rescue GoogleSearch::Error => e
      error_message = "Error performing Google Search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during Google Search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def perform_search
    api_key = ENV['GOOGLE_SEARCH_API_KEY']
    cx = ENV['GOOGLE_SEARCH_ENGINE_ID']

    search = GoogleSearch::Search.new(api_key: api_key, cx: cx)
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