require 'google/cloud/translate'

# Description: Sublayer::Action responsible for translating text from one language to another
# using Google Cloud Translation service.
#
# Initialized with text to translate, source language, and target language.
# It returns the translated text.
#
# Example usage: When you want to convert a message from one language to another,
# perhaps in a multilingual customer support scenario.

class TranslationAction < Sublayer::Actions::Base
  def initialize(text:, source_lang:, target_lang:)
    @text = text
    @source_lang = source_lang
    @target_lang = target_lang
    @client = Google::Cloud::Translate.translation_service do |config|
      config.credentials = ENV['GOOGLE_CLOUD_CREDENTIALS']
    end
  end

  def call
    begin
      response = @client.translate_text(
        contents: [@text],
        source_language_code: @source_lang,
        target_language_code: @target_lang,
        parent: "projects/#{ENV['GOOGLE_CLOUD_PROJECT']}"
      )

      translated_text = response.translations.first.translated_text
      Sublayer.configuration.logger.log(:info, "Successfully translated text from #{@source_lang} to #{@target_lang}")

      translated_text
    rescue Google::Cloud::Error => e
      error_message = "Error during translation: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
