require 'httparty'
require 'nokogiri'

# Description: Sublayer::Action that performs a web search using a specified search engine and returns the top results.
#
# It is initialized with a search query and an optional search engine (defaulting to Google).
# It returns an array of search result snippets.
#
# Example usage: When you need to augment a prompt with up-to-date information from the web, or when you want to find resources related to a specific topic.

class SearchWebAction < Sublayer::Actions::Base
  def initialize(query:, search_engine: 'google')
    @query = query
    @search_engine = search_engine.downcase
  end

  def call
    case @search_engine
    when 'google'
      search_google
    when 'bing'
      search_bing
    else
      raise ArgumentError, "Unsupported search engine: #{@search_engine}. Supported engines are 'google' and 'bing'."
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

  def search_google
    url = "https://www.google.com/search?q=#{URI.encode_www_form_component(@query)}"
    headers = {
      'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    response = HTTParty.get(url, headers: headers)
    doc = Nokogiri::HTML(response.body)
    
    results = doc.css('.tF2Cxc').map do |result|
      title = result.css('.h3').text
      snippet = result.css('.IsZvec').text
      link = result.css('.yuRUbf > a').attr('href')&.value

      { title: title, snippet: snippet, link: link }
    end

    results.reject { |r| r[:snippet].empty? }
  end

  def search_bing
    url = "https://www.bing.com/search?q=#{URI.encode_www_form_component(@query)}"
    headers = {
      'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    response = HTTParty.get(url, headers: headers)
    doc = Nokogiri::HTML(response.body)

    results = doc.css('.b_algo').map do |result|
      title = result.css('h2 > a').text
      snippet = result.css('.b_caption p').text
      link = result.css('h2 > a').attr('href')&.value

      { title: title, snippet: snippet, link: link }
    end

    results.reject { |r| r[:snippet].empty? }
  end
end