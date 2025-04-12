require 'httparty'

# Description: Sublayer::Action responsible for performing a web search using the DuckDuckGo API.
# It is initialized with a search query and returns the search results as a JSON object.
#
# Example usage: When you want to augment a prompt with information from the web or make decisions based on search results.

class WebSearchAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(query:)
    @query = query
    @api_url = 'https://api.duckduckgo.com/'
  end

  def call
    begin
      response = self.class.get(@api_url, query: { q: @query, format: 'json' })

      if response.success?
        results = response.parsed_response
        Sublayer.configuration.logger.log(:info, "Successfully performed web search for '#{@query}'")
        results
      else
        error_message = "Web search failed with HTTP status code: #{response.code}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
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
  end
end