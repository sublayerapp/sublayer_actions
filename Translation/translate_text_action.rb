# Description: Sublayer::Action responsible for translating text from one language to another using a translation API.
#
# It is initialized with the text to translate, the source language, and the target language.
# It returns the translated text.
#
# Example usage: When you want to translate user input or generated content to a different language.

class TranslateTextAction < Sublayer::Actions::Base
  def initialize(text:, source_language:, target_language:)
    @text = text
    @source_language = source_language
    @target_language = target_language
    @api_key = ENV['TRANSLATION_API_KEY'] # Ensure you have a TRANSLATION_API_KEY environment variable
  end

  def call
    begin
      translated_text = translate_text
      Sublayer.configuration.logger.log(:info, "Successfully translated text from \#{@source_language} to \#{@target_language}")
      translated_text
    rescue StandardError => e
      error_message = "Error translating text: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def translate_text
    # Replace with your actual translation API call here
    # This is a placeholder implementation
    # Make sure to handle API authentication and error responses appropriately

    # Example using a hypothetical translation API:
    # response = TranslationAPI.translate(
    #   text: @text,
    #   source_language: @source_language,
    #   target_language: @target_language,
    #   api_key: @api_key
    # )
    
    # In a real implementation, you would parse the response from the API
    # and return the translated text.

    # Placeholder response:
    "Translated text: #{@text} (from #{@source_language} to #{@target_language})"
  end
end