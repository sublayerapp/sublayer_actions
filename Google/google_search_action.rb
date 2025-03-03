require 'google/apis/customsearch_v1'
require 'googleauth'

# Description: Sublayer::Action responsible for performing a Google Search and returning a list of results.
# It is initialized with a search query and uses the Google Custom Search API to retrieve relevant search results.
#
# It returns an array of search result items, each containing title, link, and snippet.
#
# Example usage: When you want to augment a prompt with up-to-date information from the web.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 5)
    @query = query
    @num_results = num_results
    @search_engine_id = ENV['GOOGLE_SEARCH_ENGINE_ID']
    @api_key = ENV['GOOGLE_API_KEY']
  end

  def call
    begin
      service = Google::Apis::CustomsearchV1::CustomSearchAPIService.new
      service.key = @api_key

      results = service.list_cses(@query, cse_id: @search_engine_id, num: @num_results)

      search_results = results.items.map do |item|
        {
          title: item.title,
          link: item.link,
          snippet: item.snippet
        }
      end

      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@query}'")
      search_results
    rescue Google::Apis::Error => e
      error_message = "Error performing Google search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end