require 'google_search'

# Description: Sublayer::Action responsible for performing a Google search and returning snippets from the results.
#
# It is initialized with a query and returns an array of snippets from the Google search results.
#
# Example usage: When you want to provide up-to-date information to generators or agents.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:)
    @query = query
  end

  def call
    begin
      search_results = perform_google_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for query: \#{@query}")
      search_results
    rescue GoogleSearch::Error => e
      error_message = "Error performing Google search: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during Google search: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def perform_google_search
    GoogleSearch.search(@query)
    # Replace with actual Google Search API call
    # Example:
    # search = Google::Search::Web.new(@query)
    # search.get_results.map(&:content)
  end
end
