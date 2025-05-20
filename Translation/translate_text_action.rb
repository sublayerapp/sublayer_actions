require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for translating text from one language to another using a translation API.
# This action leverages the DeepL API for translation services.
#
# It is initialized with the text to translate, the target language, and optionally the source language.
# It returns the translated text.
#
# Example usage: When you want to automatically translate user input or AI-generated text for internationalization or localization purposes.

class TranslateTextAction < Sublayer::Actions::Base
  def initialize(text:, target_language:, source_language: nil)
    @text = text
    @target_language = target_language
    @source_language = source_language # Optional: If nil, DeepL will attempt to detect the source language.
    @api_key = ENV['DEEPL_API_KEY'] # Ensure DEEPL_API_KEY environment variable is set.
  end

  def call
    translate_text
  rescue StandardError => e
    error_message = "Error during text translation: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def translate_text
    uri = URI.parse('https://api.deepl.com/v2/translate')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/x-www-form-urlencoded'
    request.body = URI.encode_www_form({
      'auth_key' => @api_key,
      'text' => @text,
      'target_lang' => @target_language,
      'source_lang' => @source_language
    }.compact) # .compact removes the source_lang key if it's nil

    begin
      response = http.request(request)

      case response.code.to_i
      when 200
        translated_text = JSON.parse(response.body)['translations'][0]['text']
        Sublayer.configuration.logger.log(:info, "Text translated successfully to #{@target_language}")
        translated_text
      else
        error_message = "DeepL API Error: HTTP #{response.code} - #{response.body}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue JSON::ParserError => e
      error_message = "Error parsing DeepL API response: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error communicating with DeepL API: #{e.message}")
      raise e
    end
  end
end