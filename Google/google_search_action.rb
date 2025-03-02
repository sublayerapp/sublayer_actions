require 'google_search'

# Description: Sublayer::Action responsible for performing a Google search and returning a list of snippets and links.
# It can be used for augmenting LLM prompts with information from the internet.
#
# Requires: `google_search` gem
# $ gem install google_search
# Or add `gem 'google_search'` to your Gemfile
#
# It is initialized with a query and an optional number of results.
# It returns an array of hashes, each containing the title, link, and snippet of a search result.
#
# Example usage: When you want to augment an LLM prompt with up-to-date information from the internet.

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, num_results: 5)
    @query = query
    @num_results = num_results
  end

  def call
    begin
      search_results = perform_search
      Sublayer.configuration.logger.log(:info, "Successfully performed Google search for '#{@query}'")
      search_results
    rescue GoogleSearch::Error => e
      error_message = "Error performing Google search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error during Google search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def perform_search
    GoogleSearch.search(@query, num_results: @num_results).map do |result|
      {
        title: result.title,
        link: result.link,
        snippet: result.snippet
      }
    end
  end
end