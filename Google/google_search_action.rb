require 'google_search'

# Description: Sublayer::Action responsible for performing a Google Search and returning snippets from the results.
# This could be used to augment prompts with up-to-date information.
#
# It is initialized with a query.
# It returns an array of snippets from the search results.
#
# Example usage: When you want to augment a prompt with up-to-date information from a Google search.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:)
    @query = query
  end

  def call
    begin
      search_results = perform_google_search
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

  def perform_google_search
    GoogleSearch.results(@query)
  end
end