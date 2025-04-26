require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action enables conversion of audio content into text format, making it accessible for further
# AI processing and analysis.
#
# Requires: 'openai' gem
# $ gem install openai
# Or add `gem 'openai'` to your Gemfile
#
# It is initialized with a path to the audio file and optional parameters for transcription.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe recorded meetings, voice notes, or any audio content
# for analysis by AI agents or use in other Sublayer::Generators.

class OpenAITranscribeAudioAction < Sublayer::Actions::Base
  def initialize(audio_file_path:, language: nil, prompt: nil)
    @audio_file_path = audio_file_path
    @language = language
    @prompt = prompt
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      validate_file
      response = transcribe_audio
      
      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@audio_file_path}")
      
      response['text']
    rescue StandardError => e
      error_message = "Error transcribing audio file: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def validate_file
    unless File.exist?(@audio_file_path)
      raise StandardError, "Audio file not found at path: #{@audio_file_path}"
    end

    unless supported_audio_format?
      raise StandardError, 'Unsupported audio format. Supported formats: m4a, mp3, mp4, mpeg, mpga, wav, webm'
    end
  end

  def supported_audio_format?
    supported_formats = %w[.m4a .mp3 .mp4 .mpeg .mpga .wav .webm]
    supported_formats.include?(File.extname(@audio_file_path).downcase)
  end

  def transcribe_audio
    parameters = {
      file: File.open(@audio_file_path, 'rb'),
      model: 'whisper-1'
    }
    
    parameters[:language] = @language if @language
    parameters[:prompt] = @prompt if @prompt

    @client.audio.transcribe(parameters: parameters)
  end
end