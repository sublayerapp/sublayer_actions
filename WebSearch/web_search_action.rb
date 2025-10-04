require 'httparty'
require 'json'

# Description: Sublayer::Action responsible for performing a web search using a search engine API.
# It takes a search query as input and returns a list of search results with titles, snippets, and URLs.
#
# Example usage: When you want to augment a prompt with real-time information from the web.

class WebSearchAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(query:, search_engine: 'google', api_key: nil, cx: nil)
    @query = query
    @search_engine = search_engine.downcase
    @api_key = api_key || ENV['GOOGLE_SEARCH_API_KEY']
    @cx = cx || ENV['GOOGLE_SEARCH_CX'] # Custom Search Engine ID
  end

  def call
    case @search_engine
    when 'google'
      google_search
    else
      raise ArgumentError, "Unsupported search engine: #{@search_engine}"
    end
  rescue HTTParty::Error => e
    error_message = "HTTP error during web search: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error during web search: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def google_search
    url = "https://www.googleapis.com/customsearch/v1?key=#{@api_key}&cx=#{@cx}&q=#{@query}"
    response = self.class.get(url)

    if response.success?
      results = response['items']&.map do |item|
        {
          title: item['title'],
          snippet: item['snippet'],
          url: item['link']
        }
      end || []

      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@query}'")
      results
    else
      error_message = "Google Search API error: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end