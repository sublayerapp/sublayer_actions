require 'google_search'

# Description: Sublayer::Action responsible for performing a Google search and returning the top results.
# This action integrates with the Google Search API to fetch relevant search results based on a given query.
#
# It is initialized with a search_query and returns an array of hashes, each containing the title and URL of a search result.
#
# Example usage: When you want to augment an LLM prompt with up-to-date information from the web, or to provide
# an AI agent with the ability to search for information.

class PerformGoogleSearchAction < Sublayer::Actions::Base
  def initialize(search_query:)
    @search_query = search_query
    @api_key = ENV['GOOGLE_SEARCH_API_KEY']
    @cx = ENV['GOOGLE_SEARCH_ENGINE_ID'] # This is the Search Engine ID
  end

  def call
    begin
      search_results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@search_query}'")
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
    results = search.search(@search_query)

    results.map do |result|
      { title: result.title, url: result.url }
    end
  end
end