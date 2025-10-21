require 'openai'
require 'json'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action enables the processing of audio content into text format with timestamp data,
# making it useful for analyzing meetings, interviews, or any audio content in AI workflows.
#
# Requires: 'openai' gem
# $ gem install openai
# Or add `gem 'openai'` to your Gemfile
#
# It is initialized with an audio file path and optional parameters for language and response format.
# It returns a hash containing the transcription text and timestamps.
#
# Example usage: When you want to convert audio content into text for further AI processing,
# such as analyzing meeting recordings or generating tasks from interviews.

class WhisperTranscribeAudioAction < Sublayer::Actions::Base
  def initialize(audio_file_path:, language: nil, response_format: 'verbose_json')
    @audio_file_path = audio_file_path
    @language = language
    @response_format = response_format # Options: 'json', 'text', 'srt', 'verbose_json', 'vtt'
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      validate_file
      transcription = transcribe_audio
      process_response(transcription)
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

    unless File.size?(@audio_file_path)
      raise StandardError, "Audio file is empty"
    end

    # Check if file extension is supported by Whisper API
    valid_extensions = %w[.m4a .mp3 .mp4 .mpeg .mpga .wav .webm]
    unless valid_extensions.include?(File.extname(@audio_file_path).downcase)
      raise StandardError, "Unsupported audio file format. Supported formats: #{valid_extensions.join(', ')}"
    end
  end

  def transcribe_audio
    audio_file = File.open(@audio_file_path, 'rb')
    
    params = {
      model: 'whisper-1',
      file: audio_file,
      response_format: @response_format
    }
    params[:language] = @language if @language

    response = @client.audio.transcribe(parameters: params)

    Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@audio_file_path}")
    response
  ensure
    audio_file&.close
  end

  def process_response(response)
    case @response_format
    when 'verbose_json'
      # Return structured data with text and timestamps
      {
        text: response['text'],
        segments: response['segments'].map do |segment|
          {
            start: segment['start'],
            end: segment['end'],
            text: segment['text'].strip
          }
        end
      }
    when 'json'
      JSON.parse(response)
    else
      # For text, srt, or vtt formats, return raw response
      response
    end
  end
end
