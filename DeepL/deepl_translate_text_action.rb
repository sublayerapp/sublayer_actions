require 'httparty'

# Description: Sublayer::Action responsible for translating text from one language to another using the DeepL API.
#
# It is initialized with the text to translate, the target language code (e.g., 'EN' for English, 'DE' for German), and optionally the source language.
# It returns the translated text.
#
# Example usage: When you want to automatically translate user-generated content or provide multilingual support in your application.

class DeepL::TranslateTextAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(text:, target_lang:, source_lang: nil)
    @text = text
    @target_lang = target_lang
    @source_lang = source_lang # Optional: If not provided, DeepL will attempt to detect the source language.
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
    error_message = "Error translating text with DeepL: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def translate_text
    params = {
      auth_key: @api_key,
      text: @text,
      target_lang: @target_lang
    }

    params[:source_lang] = @source_lang if @source_lang

    response = self.class.post(@api_url, body: params)

    if response.success?
      translated_text = response.parsed_response['translations'][0]['text']
      Sublayer.configuration.logger.log(:info, "Text translated successfully to #{@target_lang}")
      translated_text
    else
      error_message = "Failed to translate text: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end