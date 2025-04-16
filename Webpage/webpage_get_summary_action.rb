require 'net/http'
require 'uri'
require 'nokogiri'

# Description: Sublayer::Action responsible for retrieving a summary of a webpage given a URL.
# This action fetches the webpage content and extracts the title and meta description tags to provide a summary.
#
# It is initialized with a webpage URL.
# It returns a hash containing the title and description of the webpage.
#
# Example usage: When you want to summarize a webpage for use in a Sublayer::Generator prompt, such as providing context to an LLM.

class Webpage\WebpageGetSummaryAction < Sublayer::Actions::Base
  def initialize(url:)
    @url = url
  end

  def call
    begin
      uri = URI.parse(@url)
      response = Net::HTTP.get_response(uri)

      unless response.is_a?(Net::HTTPSuccess)
        error_message = "Failed to fetch webpage: HTTP \#{response.code} - \#{response.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end

      html = Nokogiri::HTML(response.body)
      title = html.at_css('title')&.text
      description = html.at_css('meta[name="description"]')&.[]('content')

      summary = {
        title: title,
        description: description
      }

      Sublayer.configuration.logger.log(:info, "Successfully retrieved summary for webpage: \#{@url}")
      summary
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error retrieving webpage summary: \#{e.message}")
      raise e
    end
  end
end