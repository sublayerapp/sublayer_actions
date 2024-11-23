require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for translating text from one language to another using an external translation API.
# This action can be useful in multilingual applications or services that require dynamic language conversion.
#
# It is initialized with text, source_lang, and target_lang. Optionally, an API key can be provided.
# It returns the translated text.
#
# Example usage: When you want to translate user-generated content for international audiences.

class TranslateTextAction < Sublayer::Actions::Base
  def initialize(text:, source_lang:, target_lang:, api_key: ENV['TRANSLATION_API_KEY'])
    @text = text
    @source_lang = source_lang
    @target_lang = target_lang
    @api_key = api_key
  end

  def call
    begin
      translate_text
    rescue StandardError => e
      error_message = "Error translating text: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def translate_text
    uri = URI.parse("https://api.translation.example.com/translate")
    request = Net::HTTP::Post.new(uri)
    request.content_type = 'application/json'
    request.body = {
      text: @text,
      source_lang: @source_lang,
      target_lang: @target_lang,
      key: @api_key
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    case response.code.to_i
    when 200..299
      Sublayer.configuration.logger.log(:info, "Text translated successfully")
      JSON.parse(response.body)['translated_text']
    else
      error_message = "Failed to translate text. HTTP Response Code: #{response.code}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
