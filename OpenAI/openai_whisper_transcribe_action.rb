require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action enables speech-to-text conversion as part of AI workflows, allowing for processing
# and analysis of audio content.
#
# Requires: 'openai' gem
# $ gem install openai
# Or add `gem 'openai'` to your Gemfile
#
# It is initialized with an audio file path and optional parameters for language and response format.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe audio content for further processing or analysis in an AI workflow.

class OpenAIWhisperTranscribeAction < Sublayer::Actions::Base
  def initialize(audio_file_path:, language: nil, response_format: 'text')
    @audio_file_path = audio_file_path
    @language = language
    @response_format = response_format
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

    unless valid_audio_format?
      raise StandardError, "Invalid audio format. Supported formats: mp3, mp4, mpeg, mpga, m4a, wav, or webm"
    end
  end

  def valid_audio_format?
    valid_extensions = %w[.mp3 .mp4 .mpeg .mpga .m4a .wav .webm]
    valid_extensions.include?(File.extname(@audio_file_path).downcase)
  end

  def transcribe_audio
    parameters = {
      file: File.open(@audio_file_path, 'rb'),
      model: 'whisper-1',
      response_format: @response_format
    }

    # Add language parameter only if specified
    parameters[:language] = @language if @language

    response = @client.audio.transcribe(parameters: parameters)

    Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@audio_file_path}")

    # The response structure depends on the response_format
    # For 'text' format, the response is the transcribed text
    # For 'json' or 'verbose_json', it's a hash with additional information
    response
  end
end
