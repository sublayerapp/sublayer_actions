require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for translating text from one language to another using a translation API (e.g., Google Translate, DeepL).
# This action uses the DeepL API for translation.
#
# It is initialized with the text to translate, the source language (optional, will be auto-detected if not provided), and the target language.
# It returns the translated text.
#
# Example usage: When you want your AI agent to be able to translate user input or generated text into different languages.

class TranslateTextAction < Sublayer::Actions::Base
  def initialize(text:, target_language:, source_language: nil)
    @text = text
    @target_language = target_language
    @source_language = source_language # Optional: If nil, DeepL will auto-detect
    @api_key = ENV['DEEPL_API_KEY']
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
    uri = URI.parse("https://api.deepl.com/v2/translate")
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/x-www-form-urlencoded'

    post_params = {
      "auth_key" => @api_key,
      "text" => @text,
      "target_lang" => @target_language
    }

    post_params["source_lang"] = @source_language if @source_language

    request.body = URI.encode_www_form(post_params)

    response = https.request(request)

    case response
    when Net::HTTPSuccess
      body = JSON.parse(response.body)
      translated_text = body['translations'][0]['text']
      Sublayer.configuration.logger.log(:info, "Text translated successfully to #{@target_language}")
      translated_text
    else
      error_message = "DeepL API error: #{response.code} - #{response.body}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end