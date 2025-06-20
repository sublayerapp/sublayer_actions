require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for translating text from one language to another using a translation API.
# This action uses the Google Translate API.
#
# It is initialized with the text to translate, the source language, and the target language.
# It returns the translated text.
#
# Example usage: When you want to translate user input into a language your agent understands, or when you want to respond to a user in their native language.

class TranslateTextAction < Sublayer::Actions::Base
  def initialize(text:, source_language:, target_language:)
    @text = text
    @source_language = source_language
    @target_language = target_language
    @api_key = ENV['GOOGLE_TRANSLATE_API_KEY']
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
    uri = URI("https://translation.googleapis.com/language/translate/v2?key=#{@api_key}")
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/json'
    request.body = {
      q: @text,
      source: @source_language,
      target: @target_language,
      format: 'text'
    }.to_json

    response = https.request(request)

    case response
    when Net::HTTPSuccess
      result = JSON.parse(response.body)
      translated_text = result['data']['translations'][0]['translatedText']
      Sublayer.configuration.logger.log(:info, "Text translated successfully from #{@source_language} to #{@target_language}")
      translated_text
    else
      error_message = "Translation API request failed: #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end