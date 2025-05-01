require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action takes an audio file path and returns the transcribed text, making it useful for
# workflows that need to process audio content before sending it to LLMs or other NLP tasks.
#
# Requires: 'openai' gem
# $ gem install openai
# Or add `gem 'openai'` to your Gemfile
#
# It is initialized with a file_path to the audio file and optional parameters for the transcription.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe recorded meetings, voice notes, or any audio content
# before processing it with an LLM in your Sublayer workflow.

class TranscribeAudioFileAction < Sublayer::Actions::Base
  def initialize(file_path:, language: nil, prompt: nil)
    @file_path = file_path
    @language = language # Optional: Specify language to improve accuracy
    @prompt = prompt    # Optional: Guide the transcription with context
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      validate_file
      transcribe_audio
    rescue StandardError => e
      error_message = "Error transcribing audio file: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def validate_file
    unless File.exist?(@file_path)
      raise StandardError, "Audio file not found at path: #{@file_path}"
    end

    # Check if file is an acceptable audio format
    valid_extensions = %w[.mp3 .mp4 .mpeg .mpga .m4a .wav .webm]
    unless valid_extensions.include?(File.extname(@file_path).downcase)
      raise StandardError, "Invalid audio file format. Supported formats: #{valid_extensions.join(', ')}"
    end
  end

  def transcribe_audio
    Sublayer.configuration.logger.log(:info, "Starting transcription of #{@file_path}")

    params = {
      file: File.open(@file_path, 'rb'),
      model: 'whisper-1'
    }

    # Add optional parameters if provided
    params[:language] = @language if @language
    params[:prompt] = @prompt if @prompt

    response = @client.audio.transcribe(parameters: params)

    if response['text']
      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file")
      response['text']
    else
      raise StandardError, "No transcription text received in response"
    end
  end
end