require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action converts audio content to text, making it possible to use audio inputs in text-based AI workflows.
#
# It is initialized with the path to an audio file (supports multiple formats including mp3, mp4, mpeg, mpga, m4a, wav, webm).
# Optionally, you can specify the language and response format.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe audio content before sending it to a Sublayer::Generator for analysis or processing.

class OpenAIAudioTranscriptionAction < Sublayer::Actions::Base
  def initialize(audio_file_path:, language: nil, response_format: 'text')
    @audio_file_path = audio_file_path
    @language = language
    @response_format = response_format
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      validate_file
      response = transcribe_audio
      
      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@audio_file_path}")
      
      case @response_format
      when 'text'
        response['text']
      when 'json'
        response
      else
        response['text']
      end
    rescue StandardError => e
      error_message = "Error transcribing audio: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def validate_file
    unless File.exist?(@audio_file_path)
      raise StandardError, "Audio file not found: #{@audio_file_path}"
    end

    unless File.size?(@audio_file_path)
      raise StandardError, "Audio file is empty: #{@audio_file_path}"
    end
  end

  def transcribe_audio
    params = {
      file: File.open(@audio_file_path, 'rb'),
      model: 'whisper-1',
      response_format: @response_format
    }

    # Add language parameter only if specified
    params[:language] = @language if @language

    @client.audio.transcribe(parameters: params)
  end
end