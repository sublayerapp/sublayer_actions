require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action enables easy integration of audio transcription capabilities into Sublayer workflows,
# making it possible to process spoken content for further AI analysis.
#
# It is initialized with a path to an audio file and optional parameters for transcription.
# It returns the transcribed text from the audio file.
#
# Supported file formats: mp3, mp4, mpeg, mpga, m4a, wav, or webm
# Maximum file size: 25 MB
#
# Example usage: When you want to transcribe meeting recordings, podcasts, or voice notes
# before using the text in other Sublayer actions or generators.

class OpenAITranscribeAudioAction < Sublayer::Actions::Base
  def initialize(audio_path:, language: nil, prompt: nil)
    @audio_path = audio_path
    @language = language # optional: specify language to improve accuracy
    @prompt = prompt # optional: provide context to guide transcription
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
    unless File.exist?(@audio_path)
      raise StandardError, "Audio file not found at #{@audio_path}"
    end

    file_size = File.size(@audio_path) / (1024.0 * 1024.0) # Convert to MB
    if file_size > 25
      raise StandardError, "Audio file exceeds maximum size of 25MB (current size: #{file_size.round(2)}MB)"
    end

    extension = File.extname(@audio_path).delete('.')
    valid_formats = %w[mp3 mp4 mpeg mpga m4a wav webm]
    unless valid_formats.include?(extension.downcase)
      raise StandardError, "Invalid audio format. Supported formats: #{valid_formats.join(', ')}"
    end
  end

  def transcribe_audio
    params = {
      file: File.open(@audio_path, 'rb'),
      model: 'whisper-1'
    }

    # Add optional parameters if provided
    params[:language] = @language if @language
    params[:prompt] = @prompt if @prompt

    response = @client.audio.transcribe(parameters: params)

    if response['text']
      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@audio_path}")
      response['text']
    else
      raise StandardError, "Transcription returned no text"
    end
  end
end