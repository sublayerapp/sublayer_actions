require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action allows for converting audio content to text, which can then be used in other
# text-based AI processing workflows.
#
# Requires: 'openai' gem
# $ gem install openai
# Or add `gem 'openai'` to your Gemfile
#
# It is initialized with the path to an audio file.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe audio content for further processing or analysis
# in your Sublayer workflow, such as generating summaries or extracting insights from recorded content.

class OpenAITranscriptionAction < Sublayer::Actions::Base
  def initialize(audio_file_path:, language: nil)
    @audio_file_path = audio_file_path
    @language = language
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

    unless supported_audio_format?
      raise StandardError, "Unsupported audio format. Please use mp3, mp4, mpeg, mpga, m4a, wav, or webm"
    end
  end

  def supported_audio_format?
    supported_formats = %w[.mp3 .mp4 .mpeg .mpga .m4a .wav .webm]
    supported_formats.include?(File.extname(@audio_file_path).downcase)
  end

  def transcribe_audio
    audio_file = File.open(@audio_file_path, 'rb')
    
    params = {
      file: audio_file,
      model: 'whisper-1'
    }
    
    # Add language parameter if specified
    params[:language] = @language if @language

    response = @client.audio.transcribe(parameters: params)

    if response['text']
      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@audio_file_path}")
      response['text']
    else
      raise StandardError, "No transcription text returned from API"
    end
  ensure
    audio_file&.close
  end
end