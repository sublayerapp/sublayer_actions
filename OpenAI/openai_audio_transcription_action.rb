require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action allows for easy conversion of audio content to text within Sublayer workflows,
# making it possible to analyze audio content using LLMs.
#
# It is initialized with an audio file path and optional parameters for language and prompt.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe audio files for analysis in your Sublayer workflow,
# such as transcribing meetings, podcasts, or voice notes for further processing by LLMs.

class OpenAIAudioTranscriptionAction < Sublayer::Actions::Base
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
      raise e
    end
  end

  private

  def validate_file
    unless File.exist?(@audio_file_path)
      raise StandardError, "Audio file not found at path: #{@audio_file_path}"
    end

    unless supported_audio_format?
      raise StandardError, "Unsupported audio format. Please use m4a, mp3, mp4, mpeg, mpga, wav, or webm"
    end
  end

  def supported_audio_format?
    supported_formats = %w[.m4a .mp3 .mp4 .mpeg .mpga .wav .webm]
    supported_formats.include?(File.extname(@audio_file_path).downcase)
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
      raise StandardError, "No transcription text returned from API"
    end
  end
end