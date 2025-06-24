require 'httparty'

# Description: Sublayer::Action responsible for translating text from one language to another using a translation API.
# This action uses the DeepL API for translation.
#
# It is initialized with the text to translate, the target language, and optionally the source language.
# It returns the translated text.
#
# Example usage: When you want to translate user input or AI-generated content to a different language for international audiences.

class TranslateTextAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(text:, target_lang:, source_lang: nil)
    @text = text
    @target_lang = target_lang
    @source_lang = source_lang
    @api_key = ENV['DEEPL_API_KEY']
    @api_url = 'https://api-free.deepl.com/v2/translate'
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
    query_params = {
      auth_key: @api_key,
      text: @text,
      target_lang: @target_lang
    }
    query_params[:source_lang] = @source_lang if @source_lang

    response = self.class.post(@api_url, query: query_params)

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