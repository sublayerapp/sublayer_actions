require 'httparty'

# Description: Sublayer::Action responsible for fetching the top search results for a given query from a search engine API.
# This action integrates with a search engine API (e.g., Google Custom Search API) using HTTParty.
# It is initialized with a query, and optionally, the number of results to return.
# It returns an array of search results, each containing a title, link, and snippet.
#
# Example usage: When you want to gather information from the web to answer questions or perform tasks.

class GetSearchResultsAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(query:, num_results: 5)
    @query = query
    @num_results = num_results
    @api_key = ENV['SEARCH_ENGINE_API_KEY']
    @search_engine_id = ENV['SEARCH_ENGINE_ID'] # e.g., Google Custom Search Engine ID
  end

  def call
    fetch_search_results
  rescue HTTParty::Error => e
    error_message = "HTTP error during search: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error fetching search results: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def fetch_search_results
    url = "https://www.googleapis.com/customsearch/v1?key=#{@api_key}&cx=#{@search_engine_id}&q=#{@query}&num=#{@num_results}"
    
    response = self.class.get(url)

    if response.success?
      results = response['items']&.map do |item|
        {
          title: item['title'],
          link: item['link'],
          snippet: item['snippet']
        }
      end || []

      Sublayer.configuration.logger.log(:info, "Successfully fetched search results for query: #{@query}")
      results
    else
      error_message = "Failed to fetch search results: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end