require 'google/cloud/translate/v2'

# Description: Sublayer::Action responsible for translating text from one language to another using the Google Cloud Translation API.
# This action can be used to create multilingual applications or to facilitate communication between people who speak different languages.
#
# It is initialized with text, target_language, and optional source_language.
# It returns the translated text.
#
# Example usage: When you want to translate user input or LLM-generated content into another language.

class TranslateTextAction < Sublayer::Actions::Base
  def initialize(text:, target_language:, source_language: nil)
    @text = text
    @target_language = target_language
    @source_language = source_language
    @translate = Google::Cloud::Translate::V2.new
  end

  def call
    begin
      translation = @translate.translate @text, to: @target_language, from: @source_language
      translated_text = translation.text

      Sublayer.configuration.logger.log(:info, "Successfully translated text to \#{@target_language}")

      translated_text
    rescue Google::Cloud::Error => e
      error_message = "Error translating text: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error during translation: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end
