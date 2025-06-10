require 'google_search'

# Description: Sublayer::Action responsible for performing a Google search and returning the results.
# It uses the google_search gem to perform the search and requires a Google API key to be set in the environment variables.
#
# It is initialized with a query string and returns an array of search results. Each result includes the title, URL, and snippet.
#
# Example usage: When you need to augment a prompt with real-time information from the web.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:)
    @query = query
    @api_key = ENV['GOOGLE_API_KEY']
    @cx = ENV['GOOGLE_SEARCH_ENGINE_ID'] # Google Search Engine ID
  end

  def call
    begin
      search_results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for query: #{@query}")
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
    search = GoogleSearch::Search.new(@api_key, @cx)
    results = search.get_search(@query)

    results.map do |result|
      {
        title: result.title,
        url: result.link,
        snippet: result.snippet
      }
    end
  end
end
