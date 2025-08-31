require 'openai'

# Description: Sublayer::Action responsible for converting text to speech using OpenAI's Text-to-Speech API.
# This action generates audio content from text input, supporting multiple voices and formats.
#
# It is initialized with text content, desired voice model, and output format.
# It returns a binary string containing the audio data, which can be written to a file.
#
# Example usage: When you want to convert AI-generated text into natural-sounding speech
# for audio content, accessibility features, or voice-based applications.

class OpenAITextToSpeechAction < Sublayer::Actions::Base
  VALID_VOICES = ['alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer']
  VALID_FORMATS = ['mp3', 'opus', 'aac', 'flac']

  def initialize(text:, voice: 'alloy', format: 'mp3')
    @text = text
    @voice = validate_voice(voice)
    @format = validate_format(format)
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      response = @client.audio.speech(
        parameters: {
          model: 'tts-1',
          input: @text,
          voice: @voice,
          response_format: @format
        }
      )

      Sublayer.configuration.logger.log(:info, "Successfully generated speech audio from text")
      response
    rescue OpenAI::Error => e
      error_message = "Error generating speech: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error in text-to-speech conversion: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def validate_voice(voice)
    unless VALID_VOICES.include?(voice.downcase)
      error_message = "Invalid voice specified. Valid voices are: #{VALID_VOICES.join(', ')}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise ArgumentError, error_message
    end
    voice.downcase
  end

  def validate_format(format)
    unless VALID_FORMATS.include?(format.downcase)
      error_message = "Invalid format specified. Valid formats are: #{VALID_FORMATS.join(', ')}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise ArgumentError, error_message
    end
    format.downcase
  end
end