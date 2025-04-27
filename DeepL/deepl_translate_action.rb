require 'deepl'

# Description: Sublayer::Action responsible for translating text using the DeepL API.
# This action provides high-quality machine translation capabilities, maintaining text formatting
# and supporting a wide range of language pairs.
#
# Requires: 'deepl-rb' gem
# $ gem install deepl-rb
# Or add `gem 'deepl-rb'` to your Gemfile
#
# It is initialized with text to translate, target language, and optionally source language.
# It returns the translated text.
#
# Example usage: When you want to translate AI-generated content for international audiences
# or process multilingual content before analysis.

class DeeplTranslateAction < Sublayer::Actions::Base
  def initialize(text:, target_language:, source_language: nil, formality: nil)
    @text = text
    @target_language = target_language
    @source_language = source_language
    @formality = formality
    @translator = DeepL.configure do |config|
      config.auth_key = ENV['DEEPL_API_KEY']
      config.host = ENV['DEEPL_HOST'] || 'https://api-free.deepl.com' # Uses free API by default
    end
  end

  def call
    begin
      params = {
        text: @text,
        target_lang: @target_language.upcase
      }

      # Add optional parameters if provided
      params[:source_lang] = @source_language.upcase if @source_language
      params[:formality] = @formality if @formality

      result = DeepL.translate(**params)

      Sublayer.configuration.logger.log(:info, 
        "Successfully translated text from #{@source_language || 'auto-detected'} to #{@target_language}"
      )

      result.text
    rescue DeepL::Exceptions::AuthorizationFailed => e
      error_message = "DeepL API authentication failed: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue DeepL::Exceptions::QuotaExceeded => e
      error_message = "DeepL API quota exceeded: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue DeepL::Exceptions::Error => e
      error_message = "DeepL API error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during translation: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end