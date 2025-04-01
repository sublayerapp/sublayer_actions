require 'google_search'

# Description: Sublayer::Action responsible for performing a Google search and returning a list of results.
# This action integrates with the GoogleSearch gem to retrieve search results based on a query.
#
# Requires: 'google_search' gem
# $ gem install google_search
#
# It is initialized with a search_query and returns an array of search results, each containing the title and URL.
#
# Example usage: When you want to augment an LLM prompt with real-time information gathered from a Google search.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(search_query:)
    @search_query = search_query
  end

  def call
    begin
      results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@search_query}'")
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
    search = GoogleSearch.new(@search_query)
    search.get_response

    search.results.map do |result|
      { title: result.title, url: result.uri }
    end
  end
end