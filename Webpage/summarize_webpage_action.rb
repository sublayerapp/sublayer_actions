require 'net/http'
require 'uri'
require 'nokogiri'
require 'readability'

# Description: Sublayer::Action responsible for summarizing the content of a webpage given a URL.
# It uses the Readability gem to extract the main content and then truncates it to provide a summary.
#
# It is initialized with a url. It returns a string containing the summarized content of the webpage.
#
# Example usage: When you want to provide context to an AI agent or generator from an online resource without overwhelming it with the full page content.

class SummarizeWebpageAction < Sublayer::Actions::Base
  def initialize(url:)
    @url = url
  end

  def call
    begin
      uri = URI.parse(@url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      raise "HTTP Error: \#{response.code} - \#{response.message}" unless response.is_a?(Net::HTTPSuccess)

      html = response.body

      # Use Readability to extract the main content
      document = Nokogiri::HTML(html)
      article = Readability::Document.new(html, 
                                           :tags => %w[div p h1 h2 h3 h4 h5 h6 ul ol li blockquote img a pre code],
                                           :attributes => %w[href src alt title datetime class],
                                           :remove_empty_nodes => true)

      summary = article.content

      # Basic text cleaning (remove HTML tags, newlines, and excessive whitespace)
      text_content = Nokogiri::HTML(summary).text.gsub(/\s+/, ' ').strip

      # Truncate the content to create a summary (e.g., first 500 characters)
      truncated_summary = text_content[0..499]
      truncated_summary += '...' if text_content.length > 500

      Sublayer.configuration.logger.log(:info, "Successfully summarized webpage at \#{@url}")
      truncated_summary

    rescue StandardError => e
      error_message = "Error summarizing webpage: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end