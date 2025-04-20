require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for translating text from one language to another using a translation API.
#
# This action uses the Google Translate API to translate text.  It requires an API key and the target language.
#
# It is initialized with the text to translate, the target language code (e.g., 'es' for Spanish), and optionally the source language code.
# It returns the translated text.
#
# Example usage: When you need to translate user input or AI-generated text for international audiences.

class Translate/translate_text_action.rb < Sublayer::Actions::Base
  def initialize(text:, target_language:, source_language: nil)
    @text = text
    @target_language = target_language
    @source_language = source_language
    @api_key = ENV['GOOGLE_TRANSLATE_API_KEY']
  end

  def call
    translate_text
  rescue StandardError => e
    error_message = "Error during translation: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def translate_text
    uri = URI("https://translation.googleapis.com/language/translate/v2?key=#{@api_key}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/json'
    body = {
      q: @text,
      target: @target_language
    }
    body[:source] = @source_language if @source_language

    request.body = body.to_json

    response = http.request(request)

    case response
    when Net::HTTPSuccess
      result = JSON.parse(response.body)
      translated_text = result['data']['translations'][0]['translatedText']
      Sublayer.configuration.logger.log(:info, "Text translated successfully to #{@target_language}")
      translated_text
    else
      error_message = "Translation API error: #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end