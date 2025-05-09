require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action takes an audio file and converts it to text using state-of-the-art speech recognition.
#
# It is initialized with a file_path to the audio file and optional parameters for language and response format.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to convert audio content to text before processing it with other
# Sublayer::Generators or Actions that work with textual input.

class OpenAISpeechToTextAction < Sublayer::Actions::Base
  SUPPORTED_FORMATS = %w[mp3 mp4 mpeg mpga m4a wav webm]

  def initialize(file_path:, language: nil, response_format: 'text')
    @file_path = file_path
    @language = language
    @response_format = response_format
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    validate_file!
    
    begin
      response = transcribe_audio
      
      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@file_path}")
      
      if @response_format == 'json'
        response['text']
      else
        response
      end
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
    unless File.exist?(@file_path)
      error_message = "Audio file not found: #{@file_path}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end

    extension = File.extname(@file_path).delete('.')
    unless SUPPORTED_FORMATS.include?(extension.downcase)
      error_message = "Unsupported audio format: #{extension}. Supported formats: #{SUPPORTED_FORMATS.join(', ')}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  def transcribe_audio
    params = {
      model: 'whisper-1',
      file: File.open(@file_path, 'rb'),
      response_format: @response_format
    }
    
    params[:language] = @language if @language

    @client.audio.transcribe(parameters: params)
  end
end