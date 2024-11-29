require 'google_translate'

# Description: Sublayer::Action responsible for translating text between different languages using Google Translate.
# Takes text and target language as input and returns translated text.

class TranslateTextAction < Sublayer::Actions::Base
  def initialize(text:, target_language:)
    @text = text
    @target_language = target_language
    @translator = GoogleTranslate.new
  end

  def call
    begin
      translated_text = @translator.translate(@target_language, @text)
      Sublayer.configuration.logger.log(:info, "Successfully translated text to #{@target_language}")
      translated_text
    rescue GoogleTranslate::Error => e
      error_message = "Error translating text: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end