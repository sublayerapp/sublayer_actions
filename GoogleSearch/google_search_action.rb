require 'google_search'

# Description: Sublayer::Action responsible for performing a Google Search and returning the top results.
# It uses the google_search gem to query Google and extract URLs and snippets from the search results.
#
# It is initialized with a search query and returns a list of URLs and their corresponding snippets.
#
# Example usage: When you want to augment an LLM prompt with up-to-date information from the web.

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
      error_message = "Error during Google search: #{e.message}"
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
    search = GoogleSearch.new(query: @query)
    search.results.map do |result|
      { url: result.uri, snippet: result.content }
    end
  end
end
