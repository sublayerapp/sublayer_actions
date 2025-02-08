# Description: Sublayer::Action for translating text from one language to another using an external API.
# This action is essential for applications dealing with multilingual text processing.
#
# It is initialized with the text to be translated, the source language, and the target language.
# It returns the translated text.
#
# Example usage: Translate user input from Spanish to English before further processing in a Sublayer workflow.

require 'net/http'
require 'uri'
require 'json'

class TranslationServiceAction < Sublayer::Actions::Base
  TRANSLATION_API_URL = 'https://api.example.com/translate'.freeze

  def initialize(text:, source_lang:, target_lang:, api_key: ENV['TRANSLATION_API_KEY'])
    @text = text
    @source_lang = source_lang
    @target_lang = target_lang
    @api_key = api_key
  end

  def call
    begin
      response = translate_text
      if response.code.to_i == 200
        result = JSON.parse(response.body)
        translated_text = result['translatedText']
        Sublayer.configuration.logger.log(:info, "Translation successful")
        translated_text
      else
        handle_error(response)
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error during translation: #{e.message}")
      raise e
    end
  end

  private

  def translate_text
    uri = URI.parse(TRANSLATION_API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/json'
    request['Authorization'] = "Bearer #{@api_key}"
    request.body = {
      text: @text,
      source_lang: @source_lang,
      target_lang: @target_lang
    }.to_json
    http.request(request)
  end

  def handle_error(response)
    error_message = "Failed to translate text. HTTP Response Code: #{response.code}, Body: #{response.body}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end
end