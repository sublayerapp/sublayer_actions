require 'httparty'

# Description: Sublayer::Action responsible for performing a Google search using the SerpAPI.
# This action integrates with SerpAPI to fetch up-to-date information to augment prompts.
#
# It is initialized with a search query and an optional SerpAPI API key.
# It returns a parsed JSON response of the search results.
#
# Example usage: When you want to retrieve current information from the web to include in a prompt for better results.

class GoogleSearchAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(query:, serpapi_api_key: nil)
    @query = query
    @serpapi_api_key = serpapi_api_key || ENV['SERPAPI_API_KEY']
    raise ArgumentError, "SerpAPI API key is required" if @serpapi_api_key.nil? || @serpapi_api_key.empty?
  end

  def call
    perform_search
  rescue HTTParty::Error => e
    error_message = "HTTP error during Google search: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error performing Google search: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def perform_search
    url = "https://serpapi.com/search"
    options = {
      query: {
        q: @query,
        api_key: @serpapi_api_key,
        output: 'json' # Ensure JSON output
      }
    }

    response = self.class.get(url, options)

    if response.success?
      parsed_response = response.parsed_response
      Sublayer.configuration.logger.log(:info, "Google search successful for query: #{@query}")
      parsed_response
    else
      error_message = "Failed to perform Google search: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end