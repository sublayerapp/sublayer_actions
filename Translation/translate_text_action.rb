# Description: Sublayer::Action responsible for translating text from one language to another using a translation API.
#
# This action leverages a translation API (e.g., Google Translate, Microsoft Translator) to provide text translation capabilities.
#
# It is initialized with the text to translate, the source language, and the target language.
# It returns the translated text.
#
# Example usage: When you need to translate user input or AI-generated content for internationalization or localization purposes.

require 'net/http'
require 'uri'
require 'json'

class TranslateTextAction < Sublayer::Actions::Base
  def initialize(text:, source_language:, target_language:, translation_api_key: nil)
    @text = text
    @source_language = source_language
    @target_language = target_language
    @translation_api_key = translation_api_key || ENV['TRANSLATION_API_KEY']
    @translation_api_url = ENV['TRANSLATION_API_URL'] #URL for the translator to use. Make sure to set it in ENV
  end

  def call
    begin
      translated_text = translate_text
      Sublayer.configuration.logger.log(:info, "Successfully translated text from \#{@source_language} to \#{@target_language}")
      translated_text
    rescue StandardError => e
      error_message = "Error translating text: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def translate_text
    uri = URI(@translation_api_url)
    
    params = {
      text: @text,
      source_language: @source_language,
      target_language: @target_language,
      api_key: @translation_api_key
    }

    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)

    case response
    when Net::HTTPSuccess
      JSON.parse(response.body)['translated_text']
    else
      raise "Translation API request failed with status: #{response.code} - #{response.message}"
    end
  end
end