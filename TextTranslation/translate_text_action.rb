# Description: Sublayer::Action responsible for translating text from one language to another using a translation API.
# This action supports multilingual applications or processing international user inputs.
#
# Requires: a translation API client library, such as Google Translate or DeepL
# Ensure necessary environment variables for API access are set (e.g., API keys).
#
# It is initialized with text, source language, and target language.
# It returns the translated text.
#
# Example usage: Useful in applications that need real-time text translation for users from different regions.

class TranslateTextAction < Sublayer::Actions::Base
  def initialize(text:, source_lang:, target_lang:)
    @text = text
    @source_lang = source_lang
    @target_lang = target_lang
    @client = initialize_translation_client
  end

  def call
    begin
      response = @client.translate(
        text: @text,
        source: @source_lang,
        target: @target_lang
      )
      translated_text = response.translated_text
      Sublayer.configuration.logger.log(:info, "Text translated successfully from #{@source_lang} to #{@target_lang}")
      translated_text
    rescue TranslationAPI::Error => e
      error_message = "Error translating text: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def initialize_translation_client
    # Replace the following line with actual client initialization code from the chosen translation API
    TranslationAPI::Client.new(api_key: ENV['TRANSLATION_API_KEY'])
  end
end
