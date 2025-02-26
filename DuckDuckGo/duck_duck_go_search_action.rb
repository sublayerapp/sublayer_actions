require 'httparty'

# Description: Sublayer::Action responsible for performing a search query on DuckDuckGo and returning the top search results.
# This action integrates with DuckDuckGo using the HTTParty gem.
#
# It is initialized with a query and an optional parameter for the number of results to return.
# It returns an array of search results, each containing the title, URL, and snippet of the result.
#
# Example usage: When you want to gather information, verify facts, or augment prompts with real-time data from DuckDuckGo.

class DuckDuckGo\n  class SearchAction < Sublayer::Actions::Base
    include HTTParty
    base_uri 'api.duckduckgo.com'

    def initialize(query:, num_results: 5)
      @query = query
      @num_results = num_results
    end

    def call
      begin
        response = self.class.get('/', query: { q: @query, format: 'json', pretty: 1 })

        if response.success?
          results = parse_results(response.parsed_response)
          Sublayer.configuration.logger.log(:info, "Successfully performed DuckDuckGo search for '#{@query}'")
          results.take(@num_results)
        else
          error_message = "DuckDuckGo search failed: HTTP \#{response.code} - \#{response.message}"
          Sublayer.configuration.logger.log(:error, error_message)
          raise StandardError, error_message
        end
      rescue HTTParty::Error => e
        error_message = "HTTP error during DuckDuckGo search: \#{e.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      rescue StandardError => e
        error_message = "Error performing DuckDuckGo search: \#{e.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise e
      end
    end

    private

    def parse_results(response)
      response['RelatedTopics'].map do |result|
        {
          'title' => result['Text'] ? result['Text'].split(' - ').first : result['Name'],
          'url' => result['FirstURL'],
          'snippet' => result['Text']
        }
      end.compact
    end
  end
end