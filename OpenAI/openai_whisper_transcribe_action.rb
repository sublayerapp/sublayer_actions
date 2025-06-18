require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action enables easy integration of audio transcription capabilities into Sublayer workflows,
# making it possible to process audio content before analysis or generation tasks.
#
# It is initialized with a file_path to the audio file to transcribe.
# It returns the text transcription of the audio file.
#
# Example usage: When you want to transcribe audio content for further processing or analysis
# in your AI workflow, such as generating summaries or extracting insights from recorded meetings.

class OpenAIWhisperTranscribeAction < Sublayer::Actions::Base
  SUPPORTED_FORMATS = %w[m4a mp3 mp4 mpeg mpga wav webm].

  def initialize(file_path:)
    @file_path = file_path
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    validate_file
    transcribe_audio
  rescue StandardError => e
    error_message = "Error transcribing audio: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def validate_file
    unless File.exist?(@file_path)
      raise StandardError, "Audio file not found at path: #{@file_path}"
    end

    extension = File.extname(@file_path).delete('.')
    unless SUPPORTED_FORMATS.include?(extension)
      raise StandardError, "Unsupported audio format: #{extension}. Supported formats: #{SUPPORTED_FORMATS.join(', ')}"
    end
  end

  def transcribe_audio
    Sublayer.configuration.logger.log(:info, "Starting transcription of #{@file_path}")

    response = @client.audio.transcribe(
      parameters: {
        model: "whisper-1",
        file: File.open(@file_path)
      }
    )

    Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file")
    
    response['text']
  end
end