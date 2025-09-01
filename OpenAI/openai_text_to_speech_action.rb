require 'openai'

# Description: Sublayer::Action responsible for converting text to speech using OpenAI's TTS API.
# This action enables text-to-speech conversion for generating audio content from text data,
# particularly useful for converting LLM-generated text into spoken audio.
#
# It is initialized with text content and voice model parameters.
# It returns a base64-encoded audio string that can be saved as an audio file.
#
# Example usage: When you want to convert AI-generated text into natural-sounding speech.

class OpenAITextToSpeechAction < Sublayer::Actions::Base
  VALID_VOICES = ['alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer']
  DEFAULT_MODEL = 'tts-1'
  DEFAULT_VOICE = 'alloy'

  def initialize(text:, voice: DEFAULT_VOICE, model: DEFAULT_MODEL)
    @text = text
    @voice = validate_voice(voice)
    @model = model
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      validate_input
      response = generate_speech
      
      Sublayer.configuration.logger.log(:info, "Successfully generated speech audio for text")
      response['audio']
    rescue StandardError => e
      error_message = "Error generating speech: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def validate_input
    if @text.nil? || @text.empty?
      raise StandardError, 'Text content cannot be empty'
    end

    if @text.length > 4096
      raise StandardError, 'Text content exceeds maximum length of 4096 characters'
    end
  end

  def validate_voice(voice)
    unless VALID_VOICES.include?(voice.downcase)
      raise StandardError, "Invalid voice. Must be one of: #{VALID_VOICES.join(', ')}"
    end
    voice.downcase
  end

  def generate_speech
    @client.audio.speech.create(
      parameters: {
        model: @model,
        input: @text,
        voice: @voice,
        response_format: 'mp3'
      }
    )
  end
end