require 'deepl'

# Description: Sublayer::Action responsible for translating text using the DeepL API.
# This action provides high-quality translations between multiple languages using DeepL's translation service.
#
# Requires: 'deepl-rb' gem
# $ gem install deepl-rb
# Or add `gem 'deepl-rb'` to your Gemfile
#
# It is initialized with text to translate, target language, and optionally source language.
# It returns the translated text.
#
# Example usage: When you want to translate AI-generated content for international audiences
# or process multilingual input before sending it to LLMs.

class DeepLTranslateAction < Sublayer::Actions::Base
  def initialize(text:, target_language:, source_language: nil)
    @text = text
    @target_language = target_language
    @source_language = source_language
    @translator = DeepL.configure do |config|
      config.auth_key = ENV['DEEPL_API_KEY']
    end
  end

  def call
    begin
      translation = translate_text
      Sublayer.configuration.logger.log(:info, "Successfully translated text to #{@target_language}")
      translation.text
    rescue DeepL::Exceptions::AuthorizationFailed => e
      error_message = "DeepL API authentication failed: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue DeepL::Exceptions::QuotaExceeded => e
      error_message = "DeepL API quota exceeded: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during translation: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def translate_text
    params = {
      target_lang: @target_language.upcase
    }
    
    params[:source_lang] = @source_language.upcase if @source_language

    DeepL.translate(@text, **params)
  end
end
