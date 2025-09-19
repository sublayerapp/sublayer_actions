require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action provides easy integration of audio transcription capabilities into Sublayer workflows,
# allowing for speech-to-text conversion before LLM processing.
#
# It is initialized with a file_path to the audio file, and optionally the language and response format.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe audio content for further analysis by LLMs or
# for processing in text-based AI workflows.

class OpenAITranscriptionAction < Sublayer::Actions::Base
  def initialize(file_path:, language: nil, response_format: 'text')
    @file_path = file_path
    @language = language
    @response_format = response_format
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      validate_file
      response = transcribe_audio
      
      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@file_path}")
      
      response['text']
    rescue StandardError => e
      error_message = "Error transcribing audio: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def validate_file
    unless File.exist?(@file_path)
      raise StandardError, "Audio file not found: #{@file_path}"
    end

    unless supported_format?
      raise StandardError, "Unsupported audio format. Must be one of: mp3, mp4, mpeg, mpga, m4a, wav, or webm"
    end
  end

  def supported_format?
    supported_extensions = %w[.mp3 .mp4 .mpeg .mpga .m4a .wav .webm]
    supported_extensions.include?(File.extname(@file_path).downcase)
  end

  def transcribe_audio
    params = {
      file: File.open(@file_path, 'rb'),
      model: 'whisper-1',
      response_format: @response_format
    }

    params[:language] = @language if @language

    @client.audio.transcribe(parameters: params)
  end
end