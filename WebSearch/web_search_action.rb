require 'httparty'
require 'json'

# Description: Sublayer::Action responsible for performing a web search using the DuckDuckGo API.
# It is initialized with a search query and returns the search results in JSON format.
#
# Example usage: When you want to augment a prompt with information gathered from the web in real time, or
# when you want an AI agent to be able to search for information on its own.

class WebSearchAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(query:)
    @query = query
    @base_uri = 'https://api.duckduckgo.com/'
  end

  def call
    begin
      response = self.class.get(@base_uri, query: { q: @query, format: 'json' })

      if response.success?
        results = JSON.parse(response.body)
        Sublayer.configuration.logger.log(:info, "Successfully performed web search for '#{@query}'")
        results
      else
        error_message = "Web search failed: HTTP \#{response.code} - \#{response.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue HTTParty::Error => e
      error_message = "HTTP error during web search: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue JSON::ParserError => e
      error_message = "Error parsing web search results: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error performing web search: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end