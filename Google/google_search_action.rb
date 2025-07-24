require 'google_search'

# Description: Sublayer::Action responsible for performing a Google search and returning the top search results.
# This action uses the google_search gem to query Google and provides a list of URLs and snippets.
#
# Requires: 'google_search' gem
# $ gem install google_search
# Or add `gem 'google_search'` to your Gemfile
#
# It is initialized with a query string and an optional number of results.
# It returns an array of hashes, where each hash contains the 'url' and 'snippet' of a search result.
#
# Example usage: When you want to augment a prompt with up-to-date information from the web.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 5)
    @query = query
    @num_results = num_results
  end

  def call
    begin
      search_results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@query}'")
      search_results
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
    GoogleSearch.search(@query, num_results: @num_results).map do |result|
      { 'url' => result.uri, 'snippet' => result.content }
    end
  end
end
