require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action allows for easy integration of audio transcription capabilities into Sublayer workflows.
#
# Requires: 'openai' gem
# $ gem install openai
# Or add `gem 'openai'` to your Gemfile
#
# It is initialized with the path to an audio file and optional parameters for language and prompt.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe meeting recordings, voice notes, or any audio content
# for further processing or analysis by AI agents.

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
      raise StandardError, "Audio file not found: #{@audio_file_path}"
    end

    unless valid_audio_format?
      raise StandardError, "Invalid audio format. Supported formats: mp3, mp4, mpeg, mpga, m4a, wav, webm"
    end
  end

  def valid_audio_format?
    valid_extensions = %w[.mp3 .mp4 .mpeg .mpga .m4a .wav .webm]
    valid_extensions.include?(File.extname(@audio_file_path).downcase)
  end

  def transcribe_audio
    params = {
      file: File.open(@audio_file_path),
      model: 'whisper-1'
    }
    
    params[:language] = @language if @language
    params[:prompt] = @prompt if @prompt

    @client.audio.transcribe(parameters: params)
  end
end