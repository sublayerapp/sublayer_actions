require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action enables workflows where audio content can be transcribed and then used for analysis,
# summarization, or other NLP tasks.
#
# Requires: 'openai' gem
# $ gem install openai
# Or add `gem 'openai'` to your Gemfile
#
# It is initialized with a file_path to the audio file.
# Supported formats: mp3, mp4, mpeg, mpga, m4a, wav, or webm.
# Maximum file size: 25 MB
#
# Returns the transcribed text from the audio file.
#
# Example usage: When you want to convert spoken content to text for further processing
# with AI models or analysis.

class AudioTranscriptionAction < Sublayer::Actions::Base
  def initialize(file_path:)
    @file_path = file_path
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
    unless File.exist?(@file_path)
      raise StandardError, "Audio file not found at #{@file_path}"
    end

    unless valid_format?
      raise StandardError, "Invalid audio format. Supported formats: mp3, mp4, mpeg, mpga, m4a, wav, webm"
    end

    if File.size(@file_path) > 25 * 1024 * 1024 # 25MB in bytes
      raise StandardError, "File size exceeds 25MB limit"
    end
  end

  def valid_format?
    valid_extensions = %w[.mp3 .mp4 .mpeg .mpga .m4a .wav .webm]
    valid_extensions.include?(File.extname(@file_path).downcase)
  end

  def transcribe_audio
    audio_file = File.open(@file_path, 'rb')

    response = @client.audio.transcribe(
      parameters: {
        model: 'whisper-1',
        file: audio_file
      }
    )

    Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@file_path}")
    
    response['text']
  ensure
    audio_file&.close
  end
end