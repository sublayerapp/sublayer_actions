require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for translating text from one language to another using a translation API.
#
# This action uses the DeepL API for translation.  It requires a DeepL API key to be set in the environment variables.
#
# It is initialized with the text to translate, the source language (optional, leave nil for auto-detect), and the target language.
# It returns the translated text.
#
# Example usage: When you need to translate user input or LLM-generated text for international audiences.

class TranslateTextAction < Sublayer::Actions::Base
  def initialize(text:, target_language:, source_language: nil)
    @text = text
    @target_language = target_language
    @source_language = source_language
    @api_key = ENV['DEEPL_API_KEY']
    raise StandardError, "DEEPL_API_KEY environment variable not set" if @api_key.nil? || @api_key.empty?
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
    uri = URI('https://api-free.deepl.com/v2/translate')
    params = {
      'auth_key' => @api_key,
      'text' => @text,
      'target_lang' => @target_language
    }
    params['source_lang'] = @source_language if @source_language

    uri.query = URI.encode_www_form(params)
    
    response = Net::HTTP.get(uri)

    begin
      json_response = JSON.parse(response)
      translated_text = json_response['translations'][0]['text']
      Sublayer.configuration.logger.log(:info, "Text translated successfully to #{@target_language}")
      translated_text
    rescue JSON::ParserError => e
      error_message = "Error parsing JSON response: #{e.message}. Response: #{response}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error processing translation response: #{e.message}. Response: #{response}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end