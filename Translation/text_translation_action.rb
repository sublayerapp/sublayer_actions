require 'translator' # Assuming a hypothetical translator gem

# Description: Sublayer::Action responsible for translating text from one language to another.
# This action allows integration with a translation service.
#
# It is initialized with text, source_language, and target_language.
# It returns the translated text.
#
# Example usage: Translating user-generated content for multilingual platforms.

class TextTranslationAction < Sublayer::Actions::Base
  def initialize(text:, source_language:, target_language:)
    @text = text
    @source_language = source_language
    @target_language = target_language
    @client = Translator::Client.new(api_key: ENV['TRANSLATOR_API_KEY'])
  end

  def call
    begin
      response = @client.translate(
        text: @text,
        from: @source_language,
        to: @target_language
      )
      translated_text = response['translated_text']
      Sublayer.configuration.logger.log(:info, "Translation successful from #{@source_language} to #{@target_language}")
      translated_text
    rescue Translator::Error => e
      error_message = "Error translating text: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end