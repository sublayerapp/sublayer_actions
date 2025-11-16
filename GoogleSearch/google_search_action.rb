require 'google_search'

# Description: Sublayer::Action responsible for performing a Google search and returning the top search results.
# This action is useful for gathering up-to-date information for prompts or agents.
#
# It is initialized with a query string and returns an array of search results, each containing title, URL, and snippet.
#
# Example usage: When you need to augment an LLM prompt with current information from the web.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:)
    @query = query
    @api_key = ENV['GOOGLE_SEARCH_API_KEY']
    @cx = ENV['GOOGLE_SEARCH_ENGINE_ID'] # Search Engine ID
  end

  def call
    begin
      search_results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for query: #{@query}")
      search_results
    rescue GoogleSearch::Error => e
      error_message = "Google search failed: #{e.message}"
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
    client = GoogleSearch::Client.new(api_key: @api_key, cx: @cx)
    response = client.search(@query)

    response.items.map do |item|
      {
        title: item.title,
        url: item.link,
        snippet: item.snippet
      }
    end
  end
end
