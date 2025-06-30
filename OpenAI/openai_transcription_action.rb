require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action enables the conversion of audio content into text format for further AI processing.
#
# It is initialized with a path to the audio file and optional parameters for transcription.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe meeting recordings, voice notes, or other audio content
# for processing with LLMs or other AI systems.

class OpenAITranscriptionAction < Sublayer::Actions::Base
  SUPPORTED_FORMATS = %w[mp3 mp4 mpeg mpga m4a wav webm]

  def initialize(audio_file_path:, prompt: nil, language: nil)
    @audio_file_path = audio_file_path
    @prompt = prompt # Optional prompt to guide the transcription
    @language = language # Optional language specification
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    validate_file!

    begin
      response = @client.audio.transcribe(
        parameters: {
          model: 'whisper-1',
          file: audio_file,
          prompt: @prompt,
          language: @language
        }.compact
      )

      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@audio_file_path}")
      response['text']
    rescue OpenAI::Error => e
      error_message = "OpenAI API error during transcription: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error transcribing audio file: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    ensure
      audio_file.close if audio_file
    end
  end

  private

  def audio_file
    @audio_file ||= File.open(@audio_file_path, 'rb')
  end

  def validate_file!
    unless File.exist?(@audio_file_path)
      error_message = "Audio file not found: #{@audio_file_path}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end

    extension = File.extname(@audio_file_path).delete('.')
    unless SUPPORTED_FORMATS.include?(extension.downcase)
      error_message = "Unsupported audio format: #{extension}. Supported formats: #{SUPPORTED_FORMATS.join(', ')}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end