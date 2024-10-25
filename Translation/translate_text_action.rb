require 'your_translation_service_library'

# Description: Sublayer::Action responsible for translating text from one language to another using a specified translation service.
#
# This action is intended to be used in workflows that require multilingual support, allowing easy integration with translation services.
#
# It is initialized with the source language, target language, and text to be translated.
# It returns the translated text.
#
# Example usage: Integrating translation capability in a multilingual content generation workflow.

class TranslateTextAction < Sublayer::Actions::Base
  def initialize(source_lang:, target_lang:, text:)
    @source_lang = source_lang
    @target_lang = target_lang
    @text = text
    @client = YourTranslationService::Client.new(api_key: ENV['TRANSLATION_SERVICE_API_KEY'])
  end

  def call
    begin
      translation = @client.translate(
        source: @source_lang,
        target: @target_lang,
        text: @text
      )
      Sublayer.configuration.logger.log(:info, "Successfully translated text from \\#{@source_lang} to \\#{@target_lang}")
      translation.translated_text
    rescue YourTranslationService::Error => e
      error_message = "Error translating text: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end