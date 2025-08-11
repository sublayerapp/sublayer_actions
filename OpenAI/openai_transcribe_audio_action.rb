require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action provides easy integration of audio transcription capabilities into Sublayer workflows,
# enabling AI processing of audio content for further analysis or task generation.
#
# Requires: 'openai' gem
# $ gem install openai
# Or add `gem 'openai'` to your Gemfile
#
# It is initialized with an audio_file_path and optionally the language of the audio.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe audio content before passing it to an LLM for analysis
# or generate tasks based on spoken content.

class OpenAITranscribeAudioAction < Sublayer::Actions::Base
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

    unless allowed_audio_format?
      raise StandardError, "Invalid audio format. Supported formats: mp3, mp4, mpeg, mpga, m4a, wav, webm"
    end
  end

  def allowed_audio_format?
    allowed_extensions = %w[.mp3 .mp4 .mpeg .mpga .m4a .wav .webm]
    allowed_extensions.include?(File.extname(@audio_file_path).downcase)
  end

  def transcribe_audio
    params = {
      file: File.open(@audio_file_path, 'rb'),
      model: 'whisper-1'
    }
    
    # Add language parameter if specified
    params[:language] = @language if @language

    response = @client.audio.transcribe(parameters: params)

    if response['text']
      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@audio_file_path}")
      response['text']
    else
      raise StandardError, "No transcription text received from API"
    end
  end
end