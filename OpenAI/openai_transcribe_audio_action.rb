require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action takes an audio file path and returns the transcribed text, making it useful for
# processing audio content in AI workflows.
#
# Requires: 'openai' gem
# $ gem install openai
# Or add `gem 'openai'` to your Gemfile
#
# It is initialized with a file_path to the audio file and optionally the language of the audio.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe audio content for use in text-based AI analysis
# or to generate responses based on spoken content.

class OpenAITranscribeAudioAction < Sublayer::Actions::Base
  def initialize(file_path:, language: nil)
    @file_path = file_path
    @language = language
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      validate_file
      transcribe_audio
    rescue StandardError => e
      error_message = "Error transcribing audio file: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def validate_file
    unless File.exist?(@file_path)
      raise StandardError, "Audio file not found at #{@file_path}"
    end

    unless supported_format?
      raise StandardError, "Unsupported audio format. File must be in mp3, mp4, mpeg, mpga, m4a, wav, or webm format"
    end
  end

  def supported_format?
    supported_extensions = %w[.mp3 .mp4 .mpeg .mpga .m4a .wav .webm]
    supported_extensions.include?(File.extname(@file_path).downcase)
  end

  def transcribe_audio
    params = {
      file: File.open(@file_path, 'rb'),
      model: 'whisper-1'
    }
    
    # Add language parameter if specified
    params[:language] = @language if @language

    response = @client.audio.transcribe(parameters: params)

    if response['text']
      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@file_path}")
      response['text']
    else
      raise StandardError, "No transcription returned from API"
    end
  end
end
