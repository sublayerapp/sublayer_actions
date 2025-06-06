require 'google_search'

# Description: Sublayer::Action responsible for performing a Google search and returning the top results.
#
# This action uses the google_search gem to query Google and extract the title, URL, and snippet from the search results.
#
# It is initialized with a search query.
# It returns an array of hashes, where each hash contains the title, URL, and snippet of a search result.
#
# Example usage: When you want to augment a prompt with information from a Google search, or when you want an AI agent to automatically research a topic.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:)
    @query = query
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
      error_message = "Error during Google search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def perform_search
    GoogleSearch.search(@query).map do |result|
      {
        title: result.title,
        url: result.link,
        snippet: result.snippet
      }
    end
  end
end