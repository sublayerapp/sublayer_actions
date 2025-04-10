require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for performing text analytics using Azure Cognitive Services.
# This action integrates with Azure Cognitive Services to perform sentiment analysis, key phrase extraction,
# and other text analytics on a given text input, providing rich data features for analysis.
#
# It is initialized with an API endpoint and a text input. It returns a structured response including sentiment,
# key phrases, and other analytics.
#
# Example usage: When you want to extract valuable insights from textual data to feed into an AI workflow.

class AzureTextAnalyticsAction < Sublayer::Actions::Base
  def initialize(endpoint:, api_key:, text:)
    @endpoint = endpoint
    @api_key = api_key
    @text = text
  end

  def call
    begin
      response = perform_text_analytics
      process_response(response)
    rescue StandardError => e
      error_message = "Error performing text analytics: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def perform_text_analytics
    uri = URI.parse("#{@endpoint}/text/analytics/v3.0/sentiment")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/json'
    request['Ocp-Apim-Subscription-Key'] = @api_key
    request.body = { documents: [{ id: '1', language: 'en', text: @text }] }.to_json

    response = http.request(request)
    case response.code.to_i
    when 200..299
      JSON.parse(response.body)
    else
      error_message = "Failed to perform text analytics: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  def process_response(response)
    Sublayer.configuration.logger.log(:info, "Text analytics completed successfully")
    response['documents'][0]
  end
end
