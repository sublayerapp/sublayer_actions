require 'openai'

# Description: Sublayer::Action responsible for converting audio files to text using OpenAI's Whisper API.
# This action enables audio transcription capabilities that can feed into other AI workflows.
#
# It is initialized with an audio file path and optional parameters like language and response format.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe audio content for analysis by other Sublayer::Generators
# or for creating text-based content from audio inputs.

class OpenAISpeechToTextAction < Sublayer::Actions::Base
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
      
      response['text']
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