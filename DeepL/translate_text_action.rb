require 'deepl'

# Description: Sublayer::Action responsible for translating text from one language to another using the DeepL API.
#
# It is initialized with text to translate, a target language code, and optionally a source language code.
# It returns the translated text.
#
# Example usage: When you want to translate user input or LLM generated text into another language for international applications.

class TranslateTextAction < Sublayer::Actions::Base
  def initialize(text:, target_language_code:, source_language_code: nil)
    @text = text
    @target_language_code = target_language_code
    @source_language_code = source_language_code
    @deepl = DeepL.new(ENV['DEEPL_API_KEY'])
  end

  def call
    begin
      options = {}
      options[:source_lang] = @source_language_code if @source_language_code
      response = @deepl.translate(@text, @target_language_code, options)
      translated_text = response.text

      Sublayer.configuration.logger.log(:info, "Successfully translated text to \#{@target_language_code}")
      translated_text
    rescue DeepL::Error => e
      error_message = "Error translating text: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during translation: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end