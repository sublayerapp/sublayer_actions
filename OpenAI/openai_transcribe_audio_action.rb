require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action enables easy integration of audio transcription capabilities into Sublayer workflows,
# making audio content accessible for text-based analysis and processing.
#
# It is initialized with the path to an audio file and optional parameters for the transcription.
# It returns the transcribed text from the audio file.
#
# Supported file formats: mp3, mp4, mpeg, mpga, m4a, wav, and webm
# Maximum file size: 25 MB
#
# Example usage: When you want to transcribe audio content for further processing or analysis
# in an AI workflow, such as transcribing meetings, interviews, or voice notes.

class OpenAITranscribeAudioAction < Sublayer::Actions::Base
  def initialize(audio_file_path:, language: nil, prompt: nil)
    @audio_file_path = audio_file_path
    @language = language
    @prompt = prompt
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
      raise StandardError, "Audio file not found at path: #{@audio_file_path}"
    end

    file_size = File.size(@audio_file_path) / (1024.0 * 1024.0) # Convert to MB
    if file_size > 25
      raise StandardError, "Audio file exceeds maximum size of 25MB (file size: #{file_size.round(2)}MB)"
    end

    extension = File.extname(@audio_file_path).delete('.')
    valid_formats = %w[mp3 mp4 mpeg mpga m4a wav webm]
    unless valid_formats.include?(extension.downcase)
      raise StandardError, "Invalid audio format: #{extension}. Supported formats: #{valid_formats.join(', ')}"
    end
  end

  def transcribe_audio
    params = {
      file: File.open(@audio_file_path, 'rb'),
      model: 'whisper-1'
    }

    # Add optional parameters if they are provided
    params[:language] = @language if @language
    params[:prompt] = @prompt if @prompt

    response = @client.audio.transcribe(parameters: params)

    if response['text']
      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@audio_file_path}")
      response['text']
    else
      raise StandardError, "No transcription text returned from API"
    end
  end
end