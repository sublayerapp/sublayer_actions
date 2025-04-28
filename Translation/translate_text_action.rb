# Description: Sublayer::Action responsible for translating text from one language to another using a translation API (e.g., Google Translate).
#
# It is initialized with the text to translate, the source language, and the target language.
# It returns the translated text.
#
# Example usage: When you want to automatically translate user input or generate multi-lingual content.

class TranslateTextAction < Sublayer::Actions::Base
  def initialize(text:, source_language:, target_language:)
    @text = text
    @source_language = source_language
    @target_language = target_language
    @api_key = ENV['GOOGLE_TRANSLATE_API_KEY'] # Assuming Google Translate API
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
    require 'net/http'
    require 'uri'
    require 'json'

    url = URI("https://translation.googleapis.com/language/translate/v2?key=\##{@api_key}&source=\##{@source_language}&target=\##{@target_language}&q=\##{@text}")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(url)
    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)['data']['translations'][0]['translatedText']
    else
      raise "Translation API error: \#{response.body}"
    end
  end
end