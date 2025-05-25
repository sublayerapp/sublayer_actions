require 'openai'

# Description: Sublayer::Action responsible for converting text to speech using OpenAI's TTS API.
# This action generates audio files from text using OpenAI's text-to-speech capabilities,
# supporting different voices and output formats.
#
# It is initialized with text content, voice model, output format, and speed parameters.
# It returns the audio content as a base64-encoded string that can be saved to a file.
#
# Example usage: When you want to convert AI-generated text into natural-sounding speech
# for audio content creation, accessibility features, or voice-based applications.

class OpenAITextToSpeechAction < Sublayer::Actions::Base
  VALID_VOICES = ['alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer']
  VALID_FORMATS = ['mp3', 'opus', 'aac', 'flac']
  
  def initialize(text:, voice: 'alloy', output_format: 'mp3', speed: 1.0)
    @text = text
    @voice = validate_voice(voice)
    @output_format = validate_format(output_format)
    @speed = validate_speed(speed)
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      response = @client.audio.speech(
        parameters: {
          model: 'tts-1',
          input: @text,
          voice: @voice,
          response_format: @output_format,
          speed: @speed
        }
      )

      Sublayer.configuration.logger.log(:info, "Successfully generated speech from text")
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
    unless VALID_VOICES.include?(voice)
      error_message = "Invalid voice '#{voice}'. Must be one of: #{VALID_VOICES.join(', ')}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise ArgumentError, error_message
    end
    voice
  end

  def validate_format(format)
    unless VALID_FORMATS.include?(format)
      error_message = "Invalid format '#{format}'. Must be one of: #{VALID_FORMATS.join(', ')}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise ArgumentError, error_message
    end
    format
  end

  def validate_speed(speed)
    unless speed.is_a?(Numeric) && speed >= 0.25 && speed <= 4.0
      error_message = "Invalid speed '#{speed}'. Must be a number between 0.25 and 4.0"
      Sublayer.configuration.logger.log(:error, error_message)
      raise ArgumentError, error_message
    end
    speed
  end
end