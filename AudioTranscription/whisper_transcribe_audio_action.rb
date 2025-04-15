require 'openai'
require 'tempfile'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action enables AI workflows to process audio content and convert it to text
# for further analysis or processing.
#
# Requires: 'openai' gem
# $ gem install openai
# Or add `gem 'openai'` to your Gemfile
#
# It is initialized with the path to an audio file and optional transcription parameters.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe audio content for analysis by an LLM
# or for processing in a text-based AI workflow.
# 
# Supported audio formats: mp3, mp4, mpeg, mpga, m4a, wav, and webm

class WhisperTranscribeAudioAction < Sublayer::Actions::Base
  def initialize(audio_file_path:, language: nil, prompt: nil)
    @audio_file_path = audio_file_path
    @language = language
    @prompt = prompt
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      validate_file
      response = transcribe_audio
      
      if response['text']
        Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@audio_file_path}")
        response['text']
      else
        error_message = "No transcription text returned from the API"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue OpenAI::Error => e
      error_message = "OpenAI API error during transcription: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error transcribing audio file: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def validate_file
    unless File.exist?(@audio_file_path)
      raise StandardError, "Audio file not found: #{@audio_file_path}"
    end

    valid_extensions = %w[.mp3 .mp4 .mpeg .mpga .m4a .wav .webm]
    unless valid_extensions.include?(File.extname(@audio_file_path).downcase)
      raise StandardError, "Unsupported audio format. Supported formats: #{valid_extensions.join(', ')}"
    end
  end

  def transcribe_audio
    parameters = {
      model: 'whisper-1',
      file: File.open(@audio_file_path, 'rb')
    }

    # Add optional parameters if provided
    parameters[:language] = @language if @language
    parameters[:prompt] = @prompt if @prompt

    @client.audio.transcribe(parameters: parameters)
  end
end