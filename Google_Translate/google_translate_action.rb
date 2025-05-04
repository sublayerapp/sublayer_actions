require 'google/cloud/translate'

# Description: Sublayer::Action responsible for translating text using Google Translate API.
# This action allows for easy integration of text translation into Sublayer workflows.
#
# It is initialized with text, target_language, and optionally source_language.
# It returns the translated text.
#
# Example usage: When you want to translate text within your Sublayer workflow, such as translating user input or generating multilingual content.

class GoogleTranslateAction < Sublayer::Actions::Base
  def initialize(text:, target_language:, source_language: nil)
    @text = text
    @target_language = target_language
    @source_language = source_language
    @client = Google::Cloud::Translate.translation_service
  end

  def call
    begin
      response = @client.translate_text(
        contents: [@text],
        target_language_code: @target_language,
        source_language_code: @source_language
      )

      translated_text = response.translations.first.translated_text

      Sublayer.configuration.logger.log(:info, "Translated text successfully")

      translated_text
    rescue Google::Cloud::Error => e
      error_message = "Error translating text: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end