require 'deepl'

# Description: Sublayer::Action responsible for translating text from one language to another using the DeepL API.
#
# It is initialized with the text to translate, the target language, and optionally the source language.
# It returns the translated text.
#
# Example usage: When you want to translate user input or AI-generated content into another language.

class TranslateTextAction < Sublayer::Actions::Base
  def initialize(text:, target_language:, source_language: nil)
    @text = text
    @target_language = target_language
    @source_language = source_language
    DeepL.configure do |config|
      config.auth_key = ENV['DEEPL_API_KEY']
    end
  end

  def call
    begin
      translate
    rescue DeepL::Error => e
      error_message = "Error translating text: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def translate
    options = {}
    options[:source_lang] = @source_language if @source_language
    translation = DeepL.translate(@text, @target_language, options)
    Sublayer.configuration.logger.log(:info, "Successfully translated text to \#{@target_language}")
    translation.text
  end
end