# Description: Sublayer::Action responsible for translating text using the Google Translate API.
# It takes the text and target language as input and returns the translated text.
#
# Requires: `google-cloud-translate` gem
# $ gem install google-cloud-translate
#
# Example usage: When you want to translate text within a Sublayer workflow, for example, translating user input or generating multilingual content.

class GoogleTranslateAction < Sublayer::Actions::Base
  def initialize(text:, target_language:) 
    @text = text
    @target_language = target_language
    @translate = Google::Cloud::Translate.translation_service
  end

  def call
    begin
      translation = @translate.translate(
        @text,
        to: @target_language
      )

      Sublayer.configuration.logger.log(:info, "Successfully translated text to #{@target_language}")
      translation.text
    rescue Google::Cloud::Translate::Error => e
      error_message = "Error translating text: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end