require 'google_search'

# Description: Sublayer::Action responsible for performing a Google search and returning the top N results.
# This action uses the google_search gem to query Google and retrieve search results.
#
# Requires: 'google_search' gem
# $ gem install google_search
#
# It is initialized with a query and an optional number of results (defaulting to 3).
# It returns an array of hashes, where each hash contains the title and snippet of a search result.
#
# Example usage: When you need to gather external information from Google search for use in an AI workflow.

class GoogleSearch::GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 3)
    @query = query
    @num_results = num_results
  end

  def call
    begin
      results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@query}' and retrieved #{results.size} results.")
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
    results = []
    search.search(@num_results).each do |result|
      results << { title: result.title, snippet: result.snippet }
    end
    results
  end
end