require 'httparty'

# Description: Sublayer::Action responsible for performing a web search using the DuckDuckGo API.
# This action allows agents to gather information from the web to inform their actions or generate content.
#
# It is initialized with a search query.
# It returns the search results as a JSON object.
#
# Example usage: When you want to augment an LLM prompt with up-to-date information from the web.

class WebSearchAction < Sublayer::Actions::Base
  include HTTParty
  base_uri 'api.duckduckgo.com'

  def initialize(query:)
    @query = query
  end

  def call
    begin
      response = self.class.get('', query: { q: @query, format: 'json', pretty: 1 })

      if response.success?
        Sublayer.configuration.logger.log(:info, "Successfully performed web search for '#{@query}'")
        JSON.parse(response.body)
      else
        error_message = "Web search failed: HTTP \#{response.code} - \#{response.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
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
  end
end