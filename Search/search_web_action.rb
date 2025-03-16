require 'httparty'

# Description: Sublayer::Action responsible for performing a web search and returning the results.
# This action integrates with a search engine (default is DuckDuckGo) using the HTTParty gem.
#
# It is initialized with a search query and an optional number of results to return.  The default is 3.
# It returns an array of search results, each containing a title, URL, and snippet from the search engine.
#
# Example usage: When you want to augment a prompt with information gathered from the web in real-time.

class SearchWebAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(query:, num_results: 3)
    @query = query
    @num_results = num_results
  end

  def call
    search_results = perform_search
    Sublayer.configuration.logger.log(:info, "Successfully performed web search for '#{@query}'")
    search_results
  rescue HTTParty::Error => e
    error_message = "HTTP error during web search: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error performing web search: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def perform_search
    base_uri = 'https://api.duckduckgo.com/'
    query_params = {
      q: @query,
      format: 'json',
      pretty: 1
    }

    response = self.class.get(base_uri, query: query_params)

    if response.success?
      results = response.parsed_response['RelatedTopics']
      #DuckDuckGo returns a list of "RelatedTopics" which can be either an object with a "Text" key or a list of objects with "Text" keys
      #This code handles both cases:
      search_results = results.filter { |result| result.is_a?(Hash) && result['Text']}.map { |result|
        {
          title: result['Text'].split(' - ')[0],
          url: result['FirstURL'],
          snippet: result['Text']
        }
      }

      search_results.take(@num_results)
    else
      error_message = "Failed to perform web search: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end