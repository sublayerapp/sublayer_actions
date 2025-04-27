require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for converting text into speech using a TTS service.
# This action is useful for creating audio content or improving accessibility by providing spoken versions of AI-generated text.
#
# It is initialized with a text input and a language code, then returns a URL to the generated speech audio file.
#
# Example usage: When producing audio content from generated text prompts or enhancing user experiences with audio accessibility.

class TextToSpeechSynthesisAction < Sublayer::Actions::Base
  def initialize(text:, language_code: 'en')
    @text = text
    @language_code = language_code
    @tts_service_url = ENV['TTS_SERVICE_URL']
    @api_key = ENV['TTS_API_KEY']
  end

  def call
    generate_speech
  rescue StandardError => e
    error_message = "Error converting text to speech: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def generate_speech
    uri = URI.parse(@tts_service_url)
    request = Net::HTTP::Post.new(uri)
    request.content_type = 'application/json'
    request.body = {
      text: @text,
      language_code: @language_code,
      apiKey: @api_key
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    if response.code.to_i == 200
      audio_url = JSON.parse(response.body)['audio_url']
      Sublayer.configuration.logger.log(:info, "Successfully generated speech audio from text")
      audio_url
    else
      error_message = "Failed to generate speech audio. HTTP Response Code: #{response.code}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
