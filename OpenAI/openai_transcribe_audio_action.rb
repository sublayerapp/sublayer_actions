require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action allows for converting audio content into text format for further processing or analysis.
#
# It is initialized with a path to the audio file and optional parameters for language and response format.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe recorded meetings, voice notes, or other audio content
# before passing to Sublayer::Generator for analysis or summarization.

class OpenAITranscribeAudioAction < Sublayer::Actions::Base
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
      error_message = "Error transcribing audio file: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def validate_file
    unless File.exist?(@audio_file_path)
      raise StandardError, "Audio file not found at path: #{@audio_file_path}"
    end

    unless supported_audio_format?
      raise StandardError, "Unsupported audio format. Please use mp3, mp4, mpeg, mpga, m4a, wav, or webm"
    end
  end

  def supported_audio_format?
    supported_formats = %w[.mp3 .mp4 .mpeg .mpga .m4a .wav .webm]
    supported_formats.include?(File.extname(@audio_file_path).downcase)
  end

  def transcribe_audio
    params = {
      model: 'whisper-1',
      file: File.open(@audio_file_path, 'rb'),
      response_format: @response_format
    }

    params[:language] = @language if @language

    @client.audio.transcribe(parameters: params)
  end
end