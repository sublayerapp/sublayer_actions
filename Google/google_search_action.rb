require 'google_search'

# Description: Sublayer::Action responsible for performing a Google search and returning the top search results.
# This action is useful for AI agents that need to gather information from the web to augment their knowledge or answer questions.
#
# It is initialized with a query string.
# It returns an array of search result URLs.
#
# Example usage: When you want an AI agent to search the web for information related to a specific topic or question.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:)
    @query = query
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
      error_message = "Unexpected error during Google search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def perform_search
    # Replace with your actual Google Search API implementation or gem usage
    # This is a placeholder for demonstration purposes.
    # Ensure you have the 'google_search' gem installed or implement your own search logic.
    # For example:
    # search = GoogleSearch.new(query: @query, api_key: ENV['GOOGLE_SEARCH_API_KEY'])
    # results = search.results

    # IMPORTANT: You'll likely need to install a gem like 'google_search'
    # and configure it with your Google API key.

    # For now, let's return some dummy data.
    ["https://www.google.com/search?q=#{@query}", "https://en.wikipedia.org/wiki/#{@query}"]
  end
end