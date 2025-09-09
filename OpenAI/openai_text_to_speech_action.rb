require 'openai'

# Description: Sublayer::Action responsible for converting text to speech using OpenAI's TTS API.
# This action allows for easy conversion of text content into natural-sounding speech,
# making content more accessible or enabling audio content creation.
#
# It is initialized with text content and voice selection (alloy, echo, fable, onyx, nova, or shimmer).
# It returns the path to the generated audio file.
#
# Example usage: When you want to convert AI-generated text content into audio format
# for accessibility purposes or content creation workflows.

class OpenAITextToSpeechAction < Sublayer::Actions::Base
  VALID_VOICES = ['alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer'].freeze
  DEFAULT_MODEL = 'tts-1'.freeze
  DEFAULT_VOICE = 'alloy'.freeze
  DEFAULT_OUTPUT_FORMAT = 'mp3'.freeze

  def initialize(text:, voice: DEFAULT_VOICE, output_path: nil)
    @text = text
    @voice = validate_voice(voice)
    @output_path = output_path || generate_output_path
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      response = generate_speech
      save_audio_file(response)
      
      Sublayer.configuration.logger.log(:info, "Successfully generated speech audio at #{@output_path}")
      @output_path
    rescue OpenAI::Error => e
      error_message = "OpenAI API error during speech generation: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error generating speech: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def validate_voice(voice)
    unless VALID_VOICES.include?(voice.downcase)
      error_message = "Invalid voice option: #{voice}. Valid options are: #{VALID_VOICES.join(', ')}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise ArgumentError, error_message
    end
    voice.downcase
  end

  def generate_output_path
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    File.join(Dir.tmpdir, "tts_output_#{timestamp}.#{DEFAULT_OUTPUT_FORMAT}")
  end

  def generate_speech
    @client.audio.speech(
      parameters: {
        model: DEFAULT_MODEL,
        input: @text,
        voice: @voice
      }
    )
  end

  def save_audio_file(response)
    File.open(@output_path, 'wb') do |file|
      file.write(response)
    end
  end
end