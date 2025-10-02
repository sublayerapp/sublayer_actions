require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action enables the processing of audio content into text format for use in LLM-based workflows.
#
# Requires: 'openai' gem
# $ gem install openai
# Or add `gem 'openai'` to your Gemfile
#
# It is initialized with the path to an audio file and optional parameters for transcription.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe audio content before processing it with an LLM,
# such as transcribing meeting recordings or voice notes for analysis.

class TranscribeAudioFileAction < Sublayer::Actions::Base
  SUPPORTED_FORMATS = %w[mp3 mp4 mpeg mpga m4a wav webm]

  def initialize(audio_file_path:, language: nil, prompt: nil)
    @audio_file_path = audio_file_path
    @language = language
    @prompt = prompt
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      validate_file!
      transcribe_audio
    rescue StandardError => e
      error_message = "Error transcribing audio file: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def validate_file!
    unless File.exist?(@audio_file_path)
      raise StandardError, "Audio file not found at path: #{@audio_file_path}"
    end

    extension = File.extname(@audio_file_path).delete('.')
    unless SUPPORTED_FORMATS.include?(extension.downcase)
      raise StandardError, "Unsupported audio format: #{extension}. Supported formats: #{SUPPORTED_FORMATS.join(', ')}"
    end
  end

  def transcribe_audio
    params = {
      model: 'whisper-1',
      file: File.open(@audio_file_path, 'rb')
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