require 'httparty'
require 'nokogiri'

# Description: Sublayer::Action responsible for performing a web search and returning a list of URLs and snippets.
#
# It is initialized with a search query and an optional search engine (defaulting to Google).
# It returns an array of hashes, each containing the 'title', 'link', and 'snippet' of a search result.
#
# Example usage: When you need to gather information from the web to augment a prompt or validate user input.

class WebSearchAction < Sublayer::Actions::Base
  def initialize(query:, search_engine: 'google')
    @query = query
    @search_engine = search_engine.downcase
  end

  def call
    case @search_engine
    when 'google'
      search_google
    when 'duckduckgo'
      search_duckduckgo
    else
      raise ArgumentError, "Unsupported search engine: \#{@search_engine}. Supported engines are 'google' and 'duckduckgo'."
    end
  rescue HTTParty::Error => e
    error_message = "HTTP error during web search: \#{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error during web search: \#{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def search_google
    url = "https://www.google.com/search?q=\#{URI.encode_www_form_component(@query)}"
    headers = {
      'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'
    }
    response = HTTParty.get(url, headers: headers)
    doc = Nokogiri::HTML(response.body)
    results = []

    doc.css('.tF2Cxc').each do |result|
      title = result.css('.DKV0Md').text
      link = result.css('.yuRUbf > a').attr('href')&.value
      snippet = result.css('.lEBKkf').text

      results << { title: title, link: link, snippet: snippet } if title.present? && link.present?
    end

    Sublayer.configuration.logger.log(:info, "Successfully performed Google search for: \#{@query}")
    results
  end

  def search_duckduckgo
    url = "https://duckduckgo.com/?q=\#{URI.encode_www_form_component(@query)}&kl=wt-wt"
    headers = {
      'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3'
    }
    response = HTTParty.get(url, headers: headers)
    doc = Nokogiri::HTML(response.body)
    results = []

    doc.css('.nrn-react-div').each do |result|
      title = result.css('.title').text
      link = result.css('a').attr('href')&.value
      snippet = result.css('.description').text

      results << { title: title, link: link, snippet: snippet } if title.present? && link.present?
    end

    Sublayer.configuration.logger.log(:info, "Successfully performed DuckDuckGo search for: \#{@query}")
    results
  end
end