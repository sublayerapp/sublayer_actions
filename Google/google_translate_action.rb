# Description: Sublayer::Action to translate text from one language to another via the Google Translate API.
#
# It is initialized with text to translate and a target language, and returns the translated text.
#
# Example usage: When you need to translate user input or LLM output for internationalization or localization purposes.

require 'google/cloud/translate/v2'

class GoogleTranslateAction < Sublayer::Actions::Base
  def initialize(text:, target_language:, source_language: nil)
    @text = text
    @target_language = target_language
    @source_language = source_language # Optional: if nil, Google Translate will attempt to detect it

    @translate = Google::Cloud::Translate::V2.new
  end

  def call
    begin
      translation = @translate.translate @text, to: @target_language, from: @source_language
      translated_text = translation.text

      Sublayer.configuration.logger.log(:info, "Successfully translated text to \#{@target_language}")

      translated_text
    rescue Google::Cloud::Error => e
      error_message = "Error during Google Translate API call: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error translating text: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise
    end
  end
end