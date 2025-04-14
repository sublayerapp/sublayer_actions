require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action enables easy integration of speech-to-text capabilities into Sublayer workflows,
# allowing for audio content to be processed and analyzed by language models.
#
# Requires: 'openai' gem
# $ gem install ruby-openai
# Or add `gem 'ruby-openai'` to your Gemfile
#
# It is initialized with the path to an audio file and optional parameters like language and response format.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe audio content for analysis by an LLM in your Sublayer workflow.

class OpenAIWhisperTranscriptionAction < Sublayer::Actions::Base
  def initialize(audio_file_path:, language: nil, response_format: 'text')
    @audio_file_path = audio_file_path
    @language = language
    @response_format = response_format
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      validate_file
      
      response = @client.audio.transcribe(
        parameters: {
          model: 'whisper-1',
          file: File.open(@audio_file_path, 'rb'),
          response_format: @response_format,
          language: @language
        }
      )

      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@audio_file_path}")
      
      response.text
    rescue OpenAI::Error => e
      error_message = "OpenAI API error during transcription: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error transcribing audio file: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def validate_file
    unless File.exist?(@audio_file_path)
      error_message = "Audio file not found: #{@audio_file_path}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end

    unless valid_audio_format?
      error_message = "Invalid audio format. File must be in mp3, mp4, mpeg, mpga, m4a, wav, or webm format"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  def valid_audio_format?
    valid_extensions = %w[.mp3 .mp4 .mpeg .mpga .m4a .wav .webm]
    valid_extensions.include?(File.extname(@audio_file_path).downcase)
  end
end