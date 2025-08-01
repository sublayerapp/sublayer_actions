require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action provides easy integration for audio transcription capabilities within Sublayer workflows,
# making it possible to process audio content before sending it to generators for analysis.
#
# It is initialized with the path to an audio file and optional parameters for the transcription.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe audio content for further processing or analysis
# in your Sublayer workflow, such as generating summaries or extracting insights from audio recordings.

class OpenAIAudioTranscriptionAction < Sublayer::Actions::Base
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
      raise e
    end
  end

  private

  def validate_file
    unless File.exist?(@audio_file_path)
      raise StandardError, "Audio file not found at: #{@audio_file_path}"
    end

    unless File.size?(@audio_file_path)
      raise StandardError, "Audio file is empty: #{@audio_file_path}"
    end
  end

  def transcribe_audio
    params = {
      file: File.open(@audio_file_path, 'rb'),
      model: 'whisper-1'
    }

    params[:language] = @language if @language
    params[:prompt] = @prompt if @prompt

    response = @client.audio.transcribe(parameters: params)

    if response['text']
      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@audio_file_path}")
      response['text']
    else
      raise StandardError, "No transcription text received from API"
    end
  end
end