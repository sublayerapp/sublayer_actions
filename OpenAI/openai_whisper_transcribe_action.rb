require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action provides an easy way to convert audio content to text for further processing
# or analysis in AI workflows.
#
# Requires: 'openai' gem
# $ gem install openai
# Or add `gem 'openai'` to your Gemfile
#
# It is initialized with an audio_file_path and optionally a language hint.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe audio content before sending it through a
# Sublayer::Generator for analysis or processing.

class OpenAIWhisperTranscribeAction < Sublayer::Actions::Base
  def initialize(audio_file_path:, language: nil)
    @audio_file_path = audio_file_path
    @language = language
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      validate_file
      transcribe_audio
    rescue StandardError => e
      error_message = "Error transcribing audio: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def validate_file
    unless File.exist?(@audio_file_path)
      raise StandardError, "Audio file not found at #{@audio_file_path}"
    end

    # Check if file size is within OpenAI's limit (25MB)
    file_size_mb = File.size(@audio_file_path).to_f / (1024 * 1024)
    if file_size_mb > 25
      raise StandardError, "Audio file exceeds maximum size of 25MB"
    end
  end

  def transcribe_audio
    params = {
      file: File.open(@audio_file_path, 'rb'),
      model: 'whisper-1'
    }
    
    # Add language parameter if specified
    params[:language] = @language if @language

    response = @client.audio.transcribe(parameters: params)

    if response['text']
      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@audio_file_path}")
      response['text']
    else
      raise StandardError, "No transcription received from Whisper API"
    end
  end
end
