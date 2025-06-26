require 'google_search'

# Description: Sublayer::Action to perform a Google search and return the top search results.
#
# This action uses the google_search gem to query Google and retrieve a list of search results.
# Each result includes the URL and a snippet of the content.
#
# It is initialized with a search_query and returns an array of hashes, where each hash
# contains the 'url' and 'snippet' from the Google search result.
#
# Example usage: When you need to augment a prompt with information from a Google search, or
# when you want to automatically collect search results based on a specific query.

class PerformGoogleSearchAction < Sublayer::Actions::Base
  def initialize(search_query:)
    @search_query = search_query
  end

  def call
    begin
      results = GoogleSearch.search(@search_query)
      formatted_results = results.map { |result|
        { 'url' => result.uri, 'snippet' => result.text } # changed 'content' to 'snippet' to better match the API
      }
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@search_query}'")
      formatted_results
    rescue GoogleSearch::Error => e
      error_message = "Google search failed: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error performing Google search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end