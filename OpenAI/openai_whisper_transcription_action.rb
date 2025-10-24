require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action enables easy integration of speech-to-text capabilities into Sublayer workflows,
# making it possible to process audio content for AI analysis.
#
# Requires: 'openai' gem
# $ gem install openai
# Or add `gem 'openai'` to your Gemfile
#
# It is initialized with a path to an audio file and optional parameters for the transcription.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe audio files for analysis by an LLM in your Sublayer workflow.

class OpenAIWhisperTranscriptionAction < Sublayer::Actions::Base
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
      error_message = "Error transcribing audio: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def validate_file
    unless File.exist?(@audio_file_path)
      raise StandardError, "Audio file not found at #{@audio_file_path}"
    end

    unless supported_format?
      raise StandardError, "Unsupported audio format. Must be one of: mp3, mp4, mpeg, mpga, m4a, wav, or webm"
    end
  end

  def supported_format?
    supported_extensions = %w[.mp3 .mp4 .mpeg .mpga .m4a .wav .webm]
    supported_extensions.include?(File.extname(@audio_file_path).downcase)
  end

  def transcribe_audio
    params = {
      file: File.open(@audio_file_path, 'rb'),
      model: 'whisper-1'
    }

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