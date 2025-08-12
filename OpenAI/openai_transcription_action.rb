require 'openai'

# Description: Sublayer::Action responsible for transcribing audio/video files using OpenAI's Whisper API.
# This action converts spoken content to text, enabling processing of audio/video content in AI workflows.
#
# It is initialized with a file_path to the audio/video file and optional parameters for the transcription.
# It returns the transcribed text from the audio/video file.
#
# Supported file formats: mp3, mp4, mpeg, mpga, m4a, wav, and webm
# Maximum file size: 25 MB
#
# Example usage: When you want to process spoken content from audio/video files in your Sublayer workflow,
# such as transcribing meetings, podcasts, or video content for further analysis.

class OpenAITranscriptionAction < Sublayer::Actions::Base
  def initialize(file_path:, language: nil, prompt: nil)
    @file_path = file_path
    @language = language
    @prompt = prompt
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      validate_file
      transcribe_file
    rescue StandardError => e
      error_message = "Error transcribing file: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def validate_file
    unless File.exist?(@file_path)
      raise StandardError, "File not found: #{@file_path}"
    end

    file_size = File.size(@file_path) / (1024.0 * 1024.0) # Convert to MB
    if file_size > 25
      raise StandardError, "File size exceeds 25MB limit: #{file_size.round(2)}MB"
    end

    valid_extensions = %w[.mp3 .mp4 .mpeg .mpga .m4a .wav .webm]
    unless valid_extensions.include?(File.extname(@file_path).downcase)
      raise StandardError, "Unsupported file format: #{File.extname(@file_path)}"
    end
  end

  def transcribe_file
    params = {
      file: File.open(@file_path, 'rb'),
      model: 'whisper-1'
    }

    params[:language] = @language if @language
    params[:prompt] = @prompt if @prompt

    response = @client.audio.transcribe(parameters: params)

    if response['text']
      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@file_path}")
      response['text']
    else
      raise StandardError, "No transcription text returned from API"
    end
  end
end