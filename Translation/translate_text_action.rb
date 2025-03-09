require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for translating text from one language to another using a translation API.
# It is initialized with the text to be translated, the source language, and the target language.
# It returns the translated text.
#
# Example usage: When you want to translate user input or AI-generated text for internationalization purposes.

class TranslateTextAction < Sublayer::Actions::Base
  def initialize(text:, source_language:, target_language:)
    @text = text
    @source_language = source_language
    @target_language = target_language
    @api_key = ENV['TRANSLATION_API_KEY'] # API key should be stored in environment variables
    @api_url = ENV['TRANSLATION_API_URL'] # API URL should also be in ENV
  end

  def call
    translate_text
  rescue StandardError => e
    error_message = "Error translating text: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def translate_text
    uri = URI(@api_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'

    request = Net::HTTP::Post.new(uri.path, {"Content-Type" => "application/json"})
    request['X-API-Key'] = @api_key # Assuming API key is passed in header

    payload = {
      text: @text,
      source_language: @source_language,
      target_language: @target_language
    }.to_json

    request.body = payload

    response = http.request(request)

    case response
    when Net::HTTPSuccess
      result = JSON.parse(response.body)
      translated_text = result['translated_text'] # Adjust based on actual API response structure
      Sublayer.configuration.logger.log(:info, "Text translated successfully from #{@source_language} to #{@target_language}")
      translated_text
    else
      error_message = "Translation API error: #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end