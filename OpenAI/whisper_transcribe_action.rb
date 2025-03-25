require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action takes an audio file and converts it to text, enabling audio processing in Sublayer workflows.
#
# Requires: 'openai' gem
# $ gem install openai
# Or add `gem 'openai'` to your Gemfile
#
# It is initialized with the path to an audio file and optional parameters for the transcription.
# Supported audio formats: mp3, mp4, mpeg, mpga, m4a, wav, or webm
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe audio content before processing it with a Sublayer::Generator
# or when building workflows that need to handle audio input.

class WhisperTranscribeAction < Sublayer::Actions::Base
  def initialize(audio_file_path:, language: nil, prompt: nil)
    @audio_file_path = audio_file_path
    @language = language
    @prompt = prompt
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      validate_file
      transcribe_audio
    rescue StandardError => e
      error_message = "Error during audio transcription: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def validate_file
    unless File.exist?(@audio_file_path)
      raise StandardError, "Audio file not found at #{@audio_file_path}"
    end

    valid_extensions = %w[.mp3 .mp4 .mpeg .mpga .m4a .wav .webm]
    extension = File.extname(@audio_file_path).downcase
    unless valid_extensions.include?(extension)
      raise StandardError, "Unsupported audio format: #{extension}. Supported formats are: #{valid_extensions.join(', ')}"
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

    response = @client.audio.transcribe(parameters: params)

    if response['text']
      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@audio_file_path}")
      response['text']
    else
      raise StandardError, "No transcription returned from API"
    end
  end
end