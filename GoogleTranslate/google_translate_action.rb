require 'google/cloud/translate'

class GoogleTranslateAction < Sublayer::Actions::Base
  def initialize(text:, target_language:, source_language: 'en')
    @text = text
    @target_language = target_language
    @source_language = source_language
    @client = Google::Cloud::Translate.translation_service do |config|
      config.credentials = ENV['GOOGLE_APPLICATION_CREDENTIALS']
    end
  end

  def call
    begin
      response = @client.translate_text(
        contents: [@text],
        target_language_code: @target_language,
        parent: "projects/#{ENV['GOOGLE_PROJECT_ID']}"
      )

      translation = response.translations.first.translated_text
      Sublayer.configuration.logger.log(:info, "Successfully translated text to #{@target_language}")
      translation
    rescue Google::Cloud::Error => e
      error_message = "Error translating text: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
