require 'google_search'
require 'json'

# Description: Sublayer::Action that performs a Google Search and returns the top results.
# It uses the google_search gem and is initialized with a search query.
# The action returns a JSON array of search results, each containing the title, URL, and snippet.
#
# Example usage: When you need to augment a prompt with up-to-date information from the web.
#
# Requires:
#   gem install google_search
#
class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:)
    @query = query
  end

  def call
    begin
      results = GoogleSearch.search(@query)

      formatted_results = results.map do |result|
        {
          title: result.title,
          url: result.link,
          snippet: result.snippet
        }
      end

      Sublayer.configuration.logger.log(:info, "Successfully performed Google Search for query: #{@query}")
      JSON.generate(formatted_results)
    rescue GoogleSearch::Error => e
      error_message = "Error performing Google Search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error formatting Google Search results: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
