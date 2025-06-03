require 'httparty'
require 'json'

# Description: Sublayer::Action responsible for translating text from one language to another using the DeepL API.
#
# It is initialized with the text to translate, the target language code, and optionally the source language code.
# It returns the translated text.
#
# Example usage: When you want to translate user input or AI-generated text for internationalization or localization purposes.

class TranslateTextAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(text:, target_language:, source_language: nil)
    @text = text
    @target_language = target_language
    @source_language = source_language # Optional: If nil, DeepL will auto-detect the source language
    @api_key = ENV['DEEPL_API_KEY']
    @api_url = 'https://api.deepl.com/v2/translate'
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
    params = {
      auth_key: @api_key,
      text: @text,
      target_lang: @target_language
    }

    params[:source_lang] = @source_language if @source_language

    response = self.class.post(@api_url, body: params)

    if response.success?
      translated_text = response.parsed_response['translations'][0]['text']
      Sublayer.configuration.logger.log(:info, "Text translated successfully to #{@target_language}")
      translated_text
    else
      error_message = "Failed to translate text: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end