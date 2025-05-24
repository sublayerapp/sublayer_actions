require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action enables the conversion of audio content to text format for use in AI workflows.
#
# Requires: 'openai' gem
# $ gem install openai
# Or add `gem 'openai'` to your Gemfile
#
# It is initialized with the path to an audio file and optional parameters for the transcription.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe audio content for analysis or as input to other AI processes,
# such as processing meeting recordings or voice notes.

class WhisperTranscribeAudioAction < Sublayer::Actions::Base
  ALLOWED_FORMATS = %w[mp3 mp4 mpeg mpga m4a wav webm]
  ALLOWED_LANGUAGES = nil # nil means auto-detect, or use ISO-639-1 format like 'en', 'es', etc.

  def initialize(audio_file_path:, language: nil, prompt: nil)
    @audio_file_path = audio_file_path
    @language = language
    @prompt = prompt
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    validate_file!

    begin
      response = transcribe_audio
      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@audio_file_path}")
      response.dig('text')
    rescue OpenAI::Error => e
      error_message = "OpenAI API error during transcription: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error transcribing audio: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def validate_file!
    unless File.exist?(@audio_file_path)
      error_message = "Audio file not found: #{@audio_file_path}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end

    extension = File.extname(@audio_file_path).delete('.')
    unless ALLOWED_FORMATS.include?(extension.downcase)
      error_message = "Invalid audio format. Allowed formats: #{ALLOWED_FORMATS.join(', ')}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  def transcribe_audio
    params = {
      file: File.open(@audio_file_path, 'rb'),
      model: 'whisper-1'
    }

    params[:language] = @language if @language
    params[:prompt] = @prompt if @prompt

    @client.audio.transcribe(parameters: params)
  end
end