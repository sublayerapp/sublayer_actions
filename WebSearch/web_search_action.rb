require 'httparty'
require 'nokogiri'

# Description: Sublayer::Action responsible for performing a web search and returning a summary of the results.
# This action uses the DuckDuckGo search engine via scraping because it does not require an API key.
#
# It is initialized with a query string.
# It returns a string containing a summary of the search results.
#
# Example usage: When you need to gather information from the web to answer questions or perform research.

class WebSearchAction < Sublayer::Actions::Base
  include HTTParty

  def initialize(query:)
    @query = query
  end

  def call
    begin
      search_results = perform_search
      summary = summarize_results(search_results)
      Sublayer.configuration.logger.log(:info, "Successfully performed web search for '#{@query}'")
      summary
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

  private

  def perform_search
    url = "https://duckduckgo.com/html/?q=#{URI.encode_www_form_component(@query)}"
    response = HTTParty.get(url)

    unless response.success?
      error_message = "Web search failed: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end

    Nokogiri::HTML(response.body)
  end

  def summarize_results(html)
    results = html.css('.result__body')
    summary = results.map do |result|
      title = result.css('.result__a').text.strip
      url = result.css('.result__a')&.attr('href')&.value
      description = result.css('.result__snippet').text.strip
      "Title: #{title}\nURL: #{url}\nDescription: #{description}"
    end.join("\n\n")

    if summary.empty?
      "No relevant search results found for '#{@query}'"
    else
      summary
    end
  end
end