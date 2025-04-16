require 'google/cloud/translate'

# Description: Sublayer::Action responsible for translating text using the Google Translate API.
# This action allows for easy integration of translation capabilities into Sublayer workflows.
#
# It is initialized with the text to translate, the source language (optional, auto-detected if not provided),
# and the target language. It returns the translated text.
#
# Example usage: When you want to translate text within a Sublayer workflow, such as translating user input or generating multilingual content.

class GoogleTranslateAction < Sublayer::Actions::Base
  def initialize(text:, source_language: nil, target_language:)
    @text = text
    @source_language = source_language
    @target_language = target_language
    @client = Google::Cloud::Translate.translation_service
  end

  def call
    begin
      response = @client.translate_text(
        contents: [@text],
        source_language_code: @source_language,
        target_language_code: @target_language
      )

      translated_text = response.translations.first.translated_text

      Sublayer.configuration.logger.log(:info, "Text translated successfully to #{@target_language}")

      translated_text
    rescue StandardError => e
      error_message = "Error translating text: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end