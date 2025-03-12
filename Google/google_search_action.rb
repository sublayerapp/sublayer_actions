require 'google_search'

# Description: Sublayer::Action responsible for performing a Google Search and returning a list of URLs.
# This action is useful for gathering context and up-to-date information for generators.
#
# It is initialized with a query and an optional number of results. It returns an array of URLs.
#
# Example usage: When you want to augment a prompt with information from a Google search.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 5)
    @query = query
    @num_results = num_results
    @api_key = ENV['GOOGLE_SEARCH_API_KEY']
    @cx = ENV['GOOGLE_SEARCH_CX'] # Search Engine ID
  end

  def call
    begin
      search_results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for query: \#{@query}")
      search_results
    rescue GoogleSearch::Error => e
      error_message = "Error performing Google search: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error during Google search: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def perform_search
    search = GoogleSearch.new(api_key: @api_key, cx: @cx)
    results = search.search(@query, num: @num_results)
    results.map { |result| result.link }
  end
end