require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action converts spoken content into text for further processing by LLMs or other actions.
#
# Requires: 'openai' gem
# $ gem install openai
# Or add `gem 'openai'` to your Gemfile
#
# It is initialized with the path to an audio file. Optionally, you can specify the language
# and response format ('json' or 'text', defaults to 'text').
#
# Returns the transcribed text, or if json format is specified, returns the full response including
# timestamps and confidence scores.
#
# Example usage: When you want to transcribe an audio file before sending its content to a
# Sublayer::Generator for analysis or processing.

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

    unless valid_audio_format?
      raise StandardError, "Invalid audio format. Supported formats: mp3, mp4, mpeg, mpga, m4a, wav, webm"
    end
  end

  def valid_audio_format?
    valid_extensions = %w[.mp3 .mp4 .mpeg .mpga .m4a .wav .webm]
    valid_extensions.include?(File.extname(@audio_file_path).downcase)
  end

  def transcribe_audio
    params = {
      file: File.open(@audio_file_path, 'rb'),
      model: 'whisper-1',
      response_format: @response_format
    }

    params[:language] = @language if @language

    response = @client.audio.transcribe(parameters: params)

    if @response_format == 'text'
      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file #{@audio_file_path}")
      response
    else
      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file #{@audio_file_path} with detailed response")
      JSON.parse(response)
    end
  end
end
