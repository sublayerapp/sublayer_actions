require 'deepl'

# Description: Sublayer::Action responsible for translating text using the DeepL API.
# This action enables automated translation of content in AI workflows, making it easy
# to generate multilingual content from LLM outputs.
#
# Requires: 'deepl-rb' gem
# $ gem install deepl-rb
# Or add `gem 'deepl-rb'` to your Gemfile
#
# It is initialized with text to translate, target language code, and optional source language.
# It returns the translated text.
#
# Example usage: When you want to translate AI-generated content into different languages
# automatically as part of your workflow.

class DeeplTranslateAction < Sublayer::Actions::Base
  SUPPORTED_LANGUAGES = {
    'BG' => 'Bulgarian',
    'CS' => 'Czech',
    'DA' => 'Danish',
    'DE' => 'German',
    'EL' => 'Greek',
    'EN' => 'English',
    'ES' => 'Spanish',
    'ET' => 'Estonian',
    'FI' => 'Finnish',
    'FR' => 'French',
    'HU' => 'Hungarian',
    'ID' => 'Indonesian',
    'IT' => 'Italian',
    'JA' => 'Japanese',
    'LT' => 'Lithuanian',
    'LV' => 'Latvian',
    'NL' => 'Dutch',
    'PL' => 'Polish',
    'PT' => 'Portuguese',
    'RO' => 'Romanian',
    'RU' => 'Russian',
    'SK' => 'Slovak',
    'SL' => 'Slovenian',
    'SV' => 'Swedish',
    'TR' => 'Turkish',
    'ZH' => 'Chinese'
  }

  def initialize(text:, target_lang:, source_lang: nil)
    @text = text
    @target_lang = target_lang.upcase
    @source_lang = source_lang&.upcase
    @auth_key = ENV['DEEPL_API_KEY']
    
    validate_inputs
  end

  def call
    begin
      translator = DeepL::Translator.new(auth_key: @auth_key)
      
      params = {
        text: @text,
        target_lang: @target_lang
      }
      params[:source_lang] = @source_lang if @source_lang

      result = translator.translate_text(**params)
      
      Sublayer.configuration.logger.log(:info, "Successfully translated text to #{@target_lang}")
      result.text
    rescue DeepL::Errors::AuthorizationError => e
      error_message = "DeepL API authentication failed: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue DeepL::Errors::QuotaExceededError => e
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

  def validate_inputs
    unless @auth_key
      raise StandardError, 'DeepL API key not found in environment variables'
    end

    unless SUPPORTED_LANGUAGES.key?(@target_lang)
      raise ArgumentError, "Unsupported target language: #{@target_lang}. Supported languages: #{SUPPORTED_LANGUAGES.keys.join(', ')}"
    end

    if @source_lang && !SUPPORTED_LANGUAGES.key?(@source_lang)
      raise ArgumentError, "Unsupported source language: #{@source_lang}. Supported languages: #{SUPPORTED_LANGUAGES.keys.join(', ')}"
    end

    if @text.to_s.empty?
      raise ArgumentError, 'Text to translate cannot be empty'
    end
  end
end