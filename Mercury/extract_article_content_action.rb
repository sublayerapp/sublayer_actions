# Description: Sublayer::Action responsible for extracting the main content of a webpage from a given URL using the Mercury Web Parser API.
# This action cleans up the HTML content by removing ads, navigation, and other extraneous elements, returning the main text content.
#
# It is initialized with a url and an optional mercury_api_key. If mercury_api_key is not provided, it attempts to use the environment variable MERCURY_API_KEY.
# It returns the extracted text content of the article.
#
# Example usage: When you want to summarize articles or use web content in prompts, but need to strip away the extraneous HTML.

require 'httparty'

class ExtractArticleContentAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(url:, mercury_api_key: nil)
    @url = url
    @mercury_api_key = mercury_api_key || ENV['MERCURY_API_KEY']
    raise ArgumentError, 'Mercury API key is required' if @mercury_api_key.nil?
  end

  def call
    extract_content
  rescue HTTParty::Error => e
    error_message = "HTTP error during content extraction: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error extracting article content: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def extract_content
    url = "https://mercury.postlight.com/parser?url=#{@url}"
    headers = {
      'Content-Type' => 'application/json',
      'x-api-key' => @mercury_api_key
    }

    response = self.class.get(url, headers: headers)

    if response.success?
      content = response.parsed_response['content']
      Sublayer.configuration.logger.log(:info, "Article content extracted successfully from #{@url}")
      content
    else
      error_message = "Failed to extract article content: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end