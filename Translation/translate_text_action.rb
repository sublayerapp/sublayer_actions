require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for translating text using an external translation API.
# This action allows for translating AI-generated text into different languages, expanding accessibility and reach.
# 
# It is initialized with text to be translated, target language code, and optionally source language code.
# It returns the translated text.
#
# Example usage: When you want to translate AI-generated insights or content into multiple languages for global applications.

class TranslateTextAction < Sublayer::Actions::Base
  TRANSLATION_API_URL = "https://api.example.com/translate"  # Replace with actual API endpoint
  
  def initialize(text:, target_language:, source_language: nil)
    @text = text
    @target_language = target_language
    @source_language = source_language
  end

  def call
    translated_text = translate_text
    Sublayer.configuration.logger.log(:info, "Translation successful")
    translated_text
  rescue StandardError => e
    error_message = "Error during translation: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def translate_text
    uri = URI.parse(TRANSLATION_API_URL)
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request.body = {
      text: @text,
      target_language: @target_language,
      source_language: @source_language
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      parsed_response = JSON.parse(response.body)
      parsed_response["translated_text"]
    else
      error_message = "Failed to translate text: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end