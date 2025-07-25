require 'google/cloud/translate'

# Description: Sublayer::Action responsible for translating text from one language to another using the Google Cloud Translation API.
# This action allows for easy integration of text translation into Sublayer workflows, enabling multilingual AI applications or processing text in different languages.
#
# It is initialized with the text to translate, the source language code, and the target language code.
# It returns the translated text.
#
# Example usage: When you want to translate user input from one language to another before processing it with an LLM.

class TranslateTextAction < Sublayer::Actions::Base
  def initialize(text:, target_language_code:, source_language_code: nil)
    @text = text
    @target_language_code = target_language_code
    @source_language_code = source_language_code # Optional: let Google Translate detect the source language if not provided
    @translate = Google::Cloud::Translate.translation_service
    @project_id = ENV['GOOGLE_CLOUD_PROJECT_ID']
    raise ArgumentError, "GOOGLE_CLOUD_PROJECT_ID environment variable must be set" unless @project_id
  end

  def call
    begin
      translate_text
    rescue Google::Cloud::Error => e
      error_message = "Error translating text: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def translate_text
    request = { content: [@text],
                target_language_code: @target_language_code,
                parent: "projects/#{@project_id}" }
    request[:source_language_code] = @source_language_code if @source_language_code

    response = @translate.translate_text request

    translation = response.translations.first.translated_text
    Sublayer.configuration.logger.log(:info, "Successfully translated text to #{@target_language_code}")
    translation
  end
end