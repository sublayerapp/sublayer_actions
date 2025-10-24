require 'google_search'

# Description: Sublayer::Action responsible for performing a Google Search and returning the top search results.
# This action uses the google_search gem to query Google and retrieve search results.
#
# It is initialized with a query string.
# It returns an array of search results, each containing a title, URL, and snippet.
#
# Example usage: When you want to augment a prompt with information gathered from a Google search.

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
      error_message = "Error during Google search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def perform_search
    GoogleSearch.results(@query, num_results: 5).map do |result|
      {
        title: result.title,
        url: result.uri,
        snippet: result.content
      }
    end
  end
end