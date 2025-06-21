require 'openai'
require 'base64'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action takes an audio file path and returns the transcribed text, making it useful for
# processing meeting recordings, voice notes, or any audio content before LLM analysis.
#
# Requires: 'openai' gem
# $ gem install openai
# Or add `gem 'openai'` to your Gemfile
#
# It is initialized with an audio_file_path and optional parameters for the transcription.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe audio content for further processing by an LLM,
# such as analyzing meeting recordings or processing voice notes.

class OpenAIWhisperTranscribeAction < Sublayer::Actions::Base
  SUPPORTED_FORMATS = %w[m4a mp3 mp4 mpeg mpga wav webm].

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
      response['text']
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

  def transcribe_audio
    params = {
      file: File.open(@audio_file_path, 'rb'),
      model: 'whisper-1'
    }

    # Add optional parameters if provided
    params[:language] = @language if @language
    params[:prompt] = @prompt if @prompt

    @client.audio.transcribe(parameters: params)
  end
end