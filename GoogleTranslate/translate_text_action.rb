require 'httparty'
require 'json'

# Description: Sublayer::Action responsible for translating text from one language to another using the Google Translate API.
#
# It is initialized with the text to translate, the source language, and the target language.
# It returns the translated text.
#
# Example usage: When you want to translate user input or LLM-generated text into different languages for international audiences.

class TranslateTextAction < Sublayer::Actions::Base
  include HTTParty
  base_uri 'https://translation.googleapis.com/language/translate/v2'

  def initialize(text:, target_language:, source_language: 'auto')
    @text = text
    @target_language = target_language
    @source_language = source_language
    @api_key = ENV['GOOGLE_TRANSLATE_API_KEY']
  end

  def call
    translate_text
  rescue HTTParty::Error => e
    error_message = "HTTP error during translation: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error translating text: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def translate_text
    query = {
      key: @api_key,
      q: @text,
      target: @target_language,
      source: @source_language
    }

    response = self.class.post('', query: query)

    if response.success?
      translated_text = response['data']['translations'][0]['translatedText']
      Sublayer.configuration.logger.log(:info, "Text translated successfully to #{@target_language}")
      translated_text
    else
      error_message = "Failed to translate text: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end