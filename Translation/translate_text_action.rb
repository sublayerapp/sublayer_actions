require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for translating text from one language to another using the DeepL API.
#
# It is initialized with the text to translate, the target language code, and optionally the source language code.
# It returns the translated text.
#
# Example usage: When you want to translate user input or LLM-generated text to another language.

class TranslateTextAction < Sublayer::Actions::Base
  def initialize(text:, target_language:, source_language: nil)
    @text = text
    @target_language = target_language
    @source_language = source_language
    @api_key = ENV['DEEPL_API_KEY']
  end

  def call
    translate_text
  rescue StandardError => e
    error_message = "Error translating text: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def translate_text
    uri = URI.parse('https://api-free.deepl.com/v2/translate')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/x-www-form-urlencoded'
    request.body = URI.encode_www_form(
      'auth_key' => @api_key,
      'text' => @text,
      'target_lang' => @target_language,
      'source_lang' => @source_language
    )

    response = http.request(request)

    case response
    when Net::HTTPSuccess
      result = JSON.parse(response.body)
      translated_text = result['translations'][0]['text']
      Sublayer.configuration.logger.log(:info, "Text translated successfully to #{@target_language}")
      translated_text
    else
      error_message = "DeepL API error: #{response.code} - #{response.body}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end