require 'google_search'

# Description: Sublayer::Action responsible for performing a Google search and returning snippets or the top URLs for a given query.
# This enables agents to gather real-time information.
#
# It is initialized with a query and an optional parameter to return snippets or URLs.
# It returns an array of search results.
#
# Example usage: When you want to gather real-time information for augmenting prompts or making decisions.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, result_type: 'snippets') # result_type can be 'snippets' or 'urls'
    @query = query
    @result_type = result_type
  end

  def call
    begin
      search_results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for query: \#{@query}")
      search_results
    rescue GoogleSearch::Error => e
      error_message = "Error performing Google search: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during Google search: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def perform_search
    # Replace with actual Google Search API call or gem usage
    # This is a placeholder implementation

    # Ensure the google_search gem is installed: gem install google_search
    # or add `gem 'google_search'` to your Gemfile

    # Example using the google_search gem (replace 'YOUR_API_KEY' with your actual API key):
    # GoogleSearch.api_key = ENV['GOOGLE_SEARCH_API_KEY'] || 'YOUR_API_KEY'
    # results = GoogleSearch.search(@query)

    # For demonstration purposes, let's return a mock result:

    mock_results = [
      "Mock search result 1 for \#{@query}",
      "Mock search result 2 for \#{@query}"
    ]

    if @result_type == 'urls'
      mock_results.map { |result| "https://example.com/search?q=\#{result}" }
    else
      mock_results
    end
  end
end