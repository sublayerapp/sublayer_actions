require 'openai'

# Description: Sublayer::Action responsible for converting audio files to text using the OpenAI Whisper API.
# This action allows for easy integration of audio transcription into Sublayer workflows.
#
# It is initialized with a file_path and optionally a model. Defaults to 'whisper-1'.
# It returns the transcribed text.
#
# Example usage: When you want to transcribe audio files as part of your Sublayer workflow.

class OpenAIWhisperAudioToTextAction < Sublayer::Actions::Base
  def initialize(file_path:, model: 'whisper-1')
    @file_path = file_path
    @model = model
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      response = @client.audio.transcribe(
        parameters: {
          model: @model,
          file: File.open(@file_path, 'rb')
        }
      )

      text = response['text']

      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file \#{@file_path}")

      text
    rescue OpenAI::Error => e
      error_message = "Error transcribing audio: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
        error_message = "Error reading file: #{e.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
    end
  end
end
