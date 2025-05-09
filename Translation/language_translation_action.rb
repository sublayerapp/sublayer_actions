require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for translating text from one language to another using an external API service like Google Translate.
# This action is useful for internationalization and reaching a broader audience by translating content within a Sublayer workflow.
#
# It is initialized with the text to translate, source language, and target language.
# It returns the translated text.
#
# Example usage: Translating user-generated content or system messages for broader accessibility.

class LanguageTranslationAction < Sublayer::Actions::Base
  def initialize(text:, source_lang:, target_lang:)
    @text = text
    @source_lang = source_lang
    @target_lang = target_lang
    @api_key = ENV['TRANSLATION_API_KEY'] # Ensure your API key is set in environment variables
  end

  def call
    begin
      translated_text = translate_text
      Sublayer.configuration.logger.log(:info, "Translation successful from \\#{@source_lang} to \\#{@target_lang}")
      translated_text
    rescue StandardError => e
      error_message = "Error translating text: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def translate_text
    uri = URI.parse("https://translation.googleapis.com/language/translate/v2")
    uri.query = URI.encode_www_form({
      q: @text,
      source: @source_lang,
      target: @target_lang,
      key: @api_key
    })

    response = Net::HTTP.get_response(uri)
    handle_response(response)
  end

  def handle_response(response)
    case response
    when Net::HTTPSuccess
      body = JSON.parse(response.body)
      body.dig('data', 'translations', 0, 'translatedText')
    else
      error_message = "Failed to translate text. HTTP Response Code: \\#{response.code}"
      raise StandardError, error_message
    end
  end
end