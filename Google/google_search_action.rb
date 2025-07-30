require 'google_search'

# Description: Sublayer::Action responsible for performing a Google search and returning the results.
# This action allows a Sublayer agent to gather information from the web.
#
# It is initialized with a query string.
# It returns an array of search results, each containing a title, URL, and snippet.
#
# Example usage: When you need to augment an LLM prompt with up-to-date information from the internet.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:)
    @query = query
  end

  def call
    begin
      results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@query}'")
      results
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
    # Replace with your actual Google Search API implementation or gem usage
    # This is a placeholder to demonstrate the concept
    # Ensure you have the `google_search` gem installed or implement your own search logic
    # For example, using the `google_search` gem:
    # search = GoogleSearch.new(query: @query, api_key: ENV['GOOGLE_SEARCH_API_KEY'])
    # search.results

    # Placeholder response
    [
      {
        title: "Example Result 1",
        url: "https://example.com/1",
        snippet: "This is a snippet from example result 1."
      },
      {
        title: "Example Result 2",
        url: "https://example.com/2",
        snippet: "This is a snippet from example result 2."
      }
    ]
  end
end