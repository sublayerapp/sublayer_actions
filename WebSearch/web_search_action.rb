require 'httparty'

# Description: Sublayer::Action responsible for performing a web search using a specified search engine and returning a list of results.
# This action integrates with a search engine API using HTTParty.
#
# It is initialized with a search query and an optional search engine (defaulting to Google).
# It returns an array of search result URLs.
#
# Example usage: When you want to augment an LLM prompt with real-time information from the web.

class WebSearchAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(query:, search_engine: 'google')
    @query = query
    @search_engine = search_engine.downcase
    @api_key = ENV['GOOGLE_SEARCH_API_KEY'] # Assuming Google Custom Search API
    @search_engine_id = ENV['GOOGLE_SEARCH_ENGINE_ID'] # Assuming Google Custom Search API

    unless valid_search_engine?
      raise ArgumentError, "Unsupported search engine: \#{@search_engine}. Only 'google' is currently supported."
    end
  end

  def call
    case @search_engine
    when 'google'
      google_search
    else
      raise "Unexpected search engine. This should not happen due to validation in initialize."
    end
  rescue HTTParty::Error => e
    error_message = "HTTP error during web search: \#{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error performing web search: \#{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def valid_search_engine?
    ['google'].include?(@search_engine)
  end

  def google_search
    url = 'https://www.googleapis.com/customsearch/v1'
    query_params = {
      q: @query,
      key: @api_key,
      cx: @search_engine_id
    }

    response = self.class.get(url, query: query_params)

    if response.success?
      items = response.parsed_response['items'] || []
      search_results = items.map { |item| item['link'] }
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for: \#{@query}")
      search_results
    else
      error_message = "Google search failed: HTTP \#{response.code} - \#{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end