require 'google_search'

# Description: Sublayer::Action responsible for performing a Google search and returning the results.
#
# It is initialized with a query and optionally the number of results to return.
# It returns an array of search results, each containing a title, URL, and snippet.
#
# Example usage: When you need to augment a prompt with up-to-date information from the web.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 5)
    @query = query
    @num_results = num_results
    @api_key = ENV['GOOGLE_SEARCH_API_KEY']
    @cx = ENV['GOOGLE_SEARCH_ENGINE_ID']
  end

  def call
    begin
      search_results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@query}'")
      search_results
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
    search = GoogleSearch.new(api_key: @api_key, cx: @cx)
    response = search.search(@query, num: @num_results)

    response.items.map do |item|
      {
        title: item.title,
        url: item.link,
        snippet: item.snippet
      }
    end
  end
end