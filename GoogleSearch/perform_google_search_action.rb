require 'google_search'

# Description: Sublayer::Action responsible for performing a Google Search and returning a list of search results.
# It utilizes the google_search gem to query Google and retrieve relevant information.
#
# Requires: google_search gem
# gem install google_search
#
# It is initialized with a search query.
# It returns an array of search results, each containing a title, URL, and snippet.
#
# Example usage: When you want to augment an LLM prompt with real-time information from the web.

class PerformGoogleSearchAction < Sublayer::Actions::Base
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
    search = GoogleSearch.new(query: @query)
    search.results.map do |result|
      {
        title: result.title,
        url: result.url,
        snippet: result.snippet
      }
    end
  end
end