require 'httparty'

# Description: Sublayer::Action responsible for performing a web search and returning the top results.
# This action integrates with a search engine (default: DuckDuckGo) using HTTParty.
#
# It is initialized with a search query and optionally the search engine to use.
# It returns an array of search results, each containing a title, URL, and snippet.
#
# Example usage: When you want to augment an LLM prompt with real-time information from the web.

class PerformWebSearchAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(query:, search_engine: 'duckduckgo')
    @query = query
    @search_engine = search_engine.downcase
    @httparty_options = { follow_redirects: true, timeout: 10 }
  end

  def call
    perform_search
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
    case @search_engine
    when 'google'
      url = "https://www.googleapis.com/customsearch/v1?key=#{ENV['GOOGLE_SEARCH_API_KEY']}&cx=#{ENV['GOOGLE_SEARCH_ENGINE_ID']}&q=#{URI.encode_www_form_component(@query)}"
      response = self.class.get(url, @httparty_options)
      parse_google_results(response)

    when 'duckduckgo'
      url = "https://api.duckduckgo.com/?q=#{URI.encode_www_form_component(@query)}&format=json"
      response = self.class.get(url, @httparty_options)
      parse_duckduckgo_results(response)
    else
      raise StandardError, "Unsupported search engine: #{@search_engine}"
    end
  end

  def parse_google_results(response)
    if response.success?
      items = response.parsed_response['items'] || []
      results = items.map do |item|
        {
          title: item['title'],
          url: item['link'],
          snippet: item['snippet']
        }
      end
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@query}'")
      results
    else
      error_message = "Failed to perform Google search: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  def parse_duckduckgo_results(response)
    if response.success?
      results = response.parsed_response['RelatedTopics'].map do |item|
        {
          title: item['Text'],
          url: item['FirstURL'],
          snippet: item['Result']
        }
      end
      Sublayer.configuration.logger.log(:info, "Successfully performed DuckDuckGo search for '#{@query}'")
      results
    else
      error_message = "Failed to perform DuckDuckGo search: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end