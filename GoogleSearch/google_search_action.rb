require 'google_search'

# Description: Sublayer::Action responsible for performing a Google Search query and returning the top search results.
# This action allows AI agents to gather real-time information from the web.
#
# Requires: 'google_search' gem
# $ gem install google_search
# Or add `gem 'google_search'` to your Gemfile
#
# It is initialized with a query string.
# It returns an array of search results, each containing title, URL, and snippet.
#
# Example usage: When you want an AI agent to gather information from the web to augment its knowledge or answer user queries.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:)
    @query = query
    @api_key = ENV['GOOGLE_SEARCH_API_KEY']
    @cx = ENV['GOOGLE_SEARCH_CX'] # This is the Search Engine ID
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
    results = search.query(@query)

    results.map do |result|
      {
        title: result.title,
        url: result.link,
        snippet: result.snippet
      }
    end
  end
end
