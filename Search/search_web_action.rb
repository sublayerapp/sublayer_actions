require 'httparty'

# Description: Sublayer::Action responsible for performing a search query and returning the results.
# This action integrates with a search engine via its API (e.g., DuckDuckGo).
#
# It is initialized with a query string and returns an array of search result snippets.
#
# Example usage: When you want to augment an LLM prompt with real-time information from the web.

class SearchWebAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(query:, search_engine: 'DuckDuckGo')
    @query = query
    @search_engine = search_engine
    @base_uri = search_engine_uri(search_engine)
  end

  def call
    search
  rescue HTTParty::Error => e
    error_message = "HTTP error during search: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error during web search: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def search_engine_uri(search_engine)
    case search_engine
    when 'DuckDuckGo'
      'https://api.duckduckgo.com'
    else
      raise ArgumentError, "Unsupported search engine: #{search_engine}"
    end
  end

  def search
    case @search_engine
    when 'DuckDuckGo'
      perform_duckduckgo_search
    end
  end

  def perform_duckduckgo_search
    response = self.class.get("#{@base_uri}/?q=#{@query}&format=json&t=sublayer_action")

    if response.success?
      results = response.parsed_response['RelatedTopics'].map { |result| result['Text'] }.compact
      Sublayer.configuration.logger.log(:info, "Successfully searched DuckDuckGo for: #{@query}")
      results
    else
      error_message = "DuckDuckGo search failed: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end