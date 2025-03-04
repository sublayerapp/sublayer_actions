require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action allows for easy conversion of audio content to text within Sublayer workflows,
# making it possible to process spoken content in AI-driven applications.
#
# It is initialized with a path to an audio file and optional parameters for the transcription.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to convert spoken content to text for further processing
# in a Sublayer::Generator or other AI workflow components.

class OpenAIWhisperTranscriptionAction < Sublayer::Actions::Base
  SUPPORTED_FORMATS = %w[m4a mp3 mp4 mpeg mpga wav webm].

  def initialize(audio_file_path:, language: nil, prompt: nil)
    @audio_file_path = audio_file_path
    @language = language
    @prompt = prompt
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      validate_file!
      
      response = transcribe_audio
      
      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@audio_file_path}")
      
      response.dig('text')
    rescue StandardError => e
      error_message = "Error transcribing audio: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def validate_file!
    unless File.exist?(@audio_file_path)
      raise StandardError, "Audio file not found: #{@audio_file_path}"
    end

    extension = File.extname(@audio_file_path).delete('.')
    unless SUPPORTED_FORMATS.include?(extension)
      raise StandardError, "Unsupported audio format: #{extension}. Supported formats: #{SUPPORTED_FORMATS.join(', ')}"
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

    @client.audio.transcribe(parameters: params)
  end
end