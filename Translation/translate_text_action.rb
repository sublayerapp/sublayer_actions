# Description: Sublayer::Action responsible for translating text from one language to another using a translation API.
#
# This action leverages a translation API (e.g., Google Translate, DeepL) to translate text. It supports specifying the source and target languages.
#
# It is initialized with the text to translate, the source language code, and the target language code.
# It returns the translated text.
#
# Example usage: When you want to translate user input or LLM-generated text to support multiple languages in your application.

require 'net/http'
require 'uri'
require 'json'

class TranslateTextAction < Sublayer::Actions::Base
  def initialize(text:, source_language:, target_language:, translation_api: 'google')
    @text = text
    @source_language = source_language
    @target_language = target_language
    @translation_api = translation_to_lower(translation_api)
    @api_key = ENV['GOOGLE_TRANSLATE_API_KEY'] # Replace with the appropriate environment variable for your chosen API
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
    case @translation_api
    when 'google'
      translate_with_google
    else
      raise StandardError, "Unsupported translation API: \#{@translation_api}"
    end
  end

  def translate_with_google
    uri = URI("https://translation.googleapis.com/language/translate/v2?key=\#{ @api_key }")

    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/json'
    request.body = {
      q: @text,
      target: @target_language,
      source: @source_language
    }.to_json

    response = https.request(request)

    case response
    when Net::HTTPSuccess
      json_response = JSON.parse(response.body)
      json_response['data']['translations'][0]['translatedText']
    else
      raise StandardError, "Google Translate API error: #{response.code} - #{response.message}"
    end
  end

  def translation_api_to_lower(translation_api)
    translation_api.downcase
  end
end